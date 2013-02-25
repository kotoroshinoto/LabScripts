#!/usr/bin/env perl
#these libs are defined so testing in windows with mobaxterm works.
if($^O eq 'cygwin'){
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
	use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';
}

package PipelineUtil;
use strict;
use warnings;
# Trim both sides to remove leading/trailing whitespace
sub trim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim sub to remove leading whitespace
sub ltrim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	return $string;
}

# Right trim sub to remove trailing whitespace
sub rtrim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/\s+$//;
	return $string;
}
sub GET_SJM_START {
	my $str="";
	my $JOBNAME=shift;
	my $JOBRAM=shift;
	$str.=q(job_begin)."\n";
	$str.=q(name ${GROUPLBL}_).$JOBNAME."\n";
	$str.=q(memory ).$JOBRAM."\n";
	$str.=q(module EversonLabBiotools/1.0)."\n";
	$str.=q(queue all.q)."\n";
	$str.=q(directory ${CURDIR})."\n";
}
sub SJM_MULTILINE_JOB_START {
	my $str=GET_SJM_START @_;
	$str.=q(cmd_begin)."\n";
	return $str;
}
sub SJM_MULTILINE_JOB_CMD {
	my $str=join(" ",@_);
	return $str."\n";
}
sub SJM_MULTILINE_JOB_END {
	return "cmd_end\n";
}
sub SJM_JOB {
	my $str=GET_SJM_START @_;
	$str.=q(cmd $HANDLER_SCRIPT ).join(" ",@_)."\n";
	$str.=q(job_end)."\n";
	#print "str:\n".$str."\n";
	return $str;
}
sub SJM_JOB_AFTER {
	return  q(order ${GROUPLBL}_).$_[0].q( after ${GROUPLBL}_).$_[1];
}

1;

package AnalysisPipeline;
use Cwd;
use Cwd 'abs_path';
use File::Spec;
use File::Basename;
use strict;
use warnings;
use Graph;#http://search.cpan.org/~jhi/Graph-0.94/lib/Graph.pod
use List::Util qw( min );
use List::MoreUtils qw(uniq);
use BiotoolsSettings;
use feature 'switch';

our %jobtemplates;#list of job templates that will be used for generating the jobSteps
our $jobNameGraph=Graph->new(directed=>1,refvertexed=>1);#graph of jobnames
#our $jobGraph=Graph->new(directed=>1,refvertexed_stringified=>1);#graph of jobs
#method of output depends on options, 
#will run generator once for each set of inputs, 
#but may end up generating one or several jobfiles for each step or for the whole job.
#options will be: split_by_sample && split_by_step
#split_by_sample will not have any effect if a job unit pairs files across samples, 
#as there is no way to do this.
sub replaceVars{
	my $str=shift;
	my $subjob=shift;
	my $grouplbl=shift;
	if(!defined($grouplbl)){die "replaceVars called without grouplbl variable\n";}
	my $cumsuffix = shift;
	if(!defined($grouplbl)){die "replaceVars called without cumsuffix variable\n";}
	my ($prefix,$prefix2);
	$prefix=shift;
	if(!defined($grouplbl)){die "replaceVars called without prefix variable\n";}
	if(${$subjob}->{parent}->{isCrossJob}){
		$prefix2=shift;
		if(!defined($grouplbl)){die "replaceVars called on crossjob without prefix2 variable\n";}
	}else {$prefix2="";}
	my $search;
	my $replace;
	#replace custom variables
	for my $var(keys(%{${$subjob}->{parent}->{vars}})){
		$search=$var;
		$replace=${$subjob}->{parent}->{vars}->{$var};
		$search=~s/\$/\\\$/g;
		#$replace=~s/\$/'\$'/g;
		#print "replacing $search with $replace\n";
		$str=~s/$search/$replace/g;
	}
	
	#replace ADJPREFIX with $PREFIX$CUMSUFFIX - totally for convenience, can still use $CUMSUFFIX directly, for input files that need it
	if(!defined($cumsuffix)){$cumsuffix="";}
	if(!${$subjob}->{parent}->{clearsuffixes}){
		$str=~s/\$ADJPREFIX/\$PREFIX\$CUMSUFFIX/g;
	} else {
		$str=~s/\$ADJPREFIX/\$PREFIX/g;
	}
	$str=~s/\$CUMSUFFIX/$cumsuffix/g;
	my $suffix=${$subjob}->{parent}->{suffix};
	#print "suffix: $suffix","\n";
	$str=~s/\$SUFFIX/$suffix/g;
	
	#replace standard variables
	for my $key(keys(%{SettingsLib::SettingsList})){
		$search='\$'.$key;
		$replace=${SettingsLib::SettingsList}{$key};
		#print "search $search : replace $replace\n";
		$str=~s/$search/$replace/g;
	}
	#replace remaining filename vars
	
	$str=~s/\$GROUPLBL/$grouplbl/g;
	$str=~s/\$CUMSUFFIX/$cumsuffix/g;
	$str=~s/\$PREFIX/$prefix/g;
	if(${$subjob}->{parent}->{isCrossJob}){
		$str=~s/\$PREFIX2/$prefix2/g;
	}
	return $str;
}
sub parseAssume{
	my $string=shift;
	my @assume_vertices=parsePipeline($string);#store them to mark them "done" and then return them
	for my $vertex(@assume_vertices){
		#TODO mark done
	}
	return uniq @assume_vertices; 
}
sub parsePipeline{
	my $string=shift;
	my @splitcomma=split(',',$string);
	my @splitdash;
	my %jobdeps;
	my @jobnames;
	my ($step,$parent);
	#print "splitcomma: @splitcomma\n";
	for my $commaItem(@splitcomma){
		#print "commaItem: $commaItem\n";
		@splitdash=split('-',$commaItem);
		#print "splitdash: @splitdash\n";
		if(scalar(@splitdash)==2){
			$step=$splitdash[1];
			$parent=$splitdash[0];
		} else {
			$step=$splitdash[0];
			$parent="";
		}
		#print STDERR "Declaring Step: $step\n";
		#print STDERR "\thas_parent: $parent\n";
		if(!defined($jobdeps{$step})){
			$jobdeps{$step}=[];
			push(@jobnames,$step);
		}
		if(defined($parent) && length($parent) > 0 && !defined($jobdeps{$parent})){
			$jobdeps{$parent}=[];
			push(@jobnames,$parent);
		}
		push(@{$jobdeps{$step}},$parent);
	}
	for my $job(@jobnames){
		#print "adding Step: $job with parents @{$jobdeps{$job}}\n";
		addStep($job,@{$jobdeps{$job}});
	}
	return uniq @jobnames;
}


sub parseBrackets{
	my $string=shift;
	my $namestr=shift;
	my $brackets=shift;
	my $start=index($string,'[');
	my $end=index($string,']');
	
	if($start > 0){
		if($end > 0){
			#print STDERR "string: $string\n";
			${$brackets}=substr($string,$start+1,$end-$start-1);
			#print STDERR "parentstr: $parentstr\n";
			${$namestr}=substr($string,0,$start);
			#print STDERR "namestr: ${$namestr}\n";
			
		} else {
			die "INVALID FORMAT (unpaired '[')\n";
		}
	} elsif($end > 0) {
		die "INVALID FORMAT (unpaired ']')\n";
	} else {
		${$namestr}=$string;
	}
}


sub addStep{
	my $StepName=shift;
	my @parents=uniq @_;
	print STDERR "Adding Step: $StepName with parents: @parents\n";
	if(! $jobNameGraph->has_vertex($StepName)){
		$jobNameGraph->add_vertex($StepName);
		require_jobdef($StepName);
	}
	for my $parent(@parents){
		if(defined($parent) && length($parent)>0){
			if(! $jobNameGraph->has_vertex($parent)){
				$jobNameGraph->add_vertex($parent);
				require_jobdef($parent);
				#die("SYNTAX ERROR, Step \"$parent\" used as parent before it was defined\n");
			}
			if(! $jobNameGraph->has_edge($parent,$StepName)){
				$jobNameGraph->add_edge($parent,$StepName);
			}
		}
	}
	if($jobNameGraph->has_a_cycle){
		die "JobGraph became cyclic! Cannot issue cyclic jobs!\n";
	}
}

sub charAt { return substr($_[0],$_[1],1); }

sub require_jobdef{
	my $step_name=shift;
	#DONE check if step template is already loaded
	#if not found, check if template exists & load it
	my $path=TemplateDir();
	my $file=File::Spec->catfile($path,uc($step_name).'.sjt');
	unless (load_template(uc($step_name),$file)) {
		die "There is no template for step \"$step_name\" & it is not defined manually\n";
	}
}

sub load_template {
	my $step_name=shift;
	my $filename=shift;
	print STDERR "\tloading template[$step_name]: $filename\n";
	unless (-e $filename){
		return 0;
	}
	my $file=FileHandle->new("< $filename") or die "error with template file($filename): $!\n";
	my @lines=<$file>;
	my $stepTemplate;
	$stepTemplate=PipelineStep->readTemplate(@lines);
	return 1;
}

sub TemplateDir{
	my($filename, $directories, $suffix) = fileparse($0);
	my $templatedir=abs_path("$directories");
	$templatedir=File::Spec->catdir($templatedir,'jobtemplates');
	#print STDERR  "$templatedir\n";
}

sub new {
	my $class = shift;
	my $self = {};
	$self->{name}=undef;#pipeline name
	$self->{jobs}={};#hash of subjobs: jobname=>object format
	$self->{log_dir}=undef;
	bless $self,$class;
	return $self;
}

sub getOutputPrefix {
	my $self=shift;
	my $inputfile=shift;
}

sub parselines {
	
}
1;

package PipelineStep;#template file unit

sub new {
	my $class = shift;
	my $self = {};
	#list of files this pipeline uses
	#(only need to include files produced by previous steps that you need)
	$self->{suffix}={};#this suffix will be appended to the accumulated suffixes for the next job's use with $ADJPREFIX 
	$self->{clearsuffixes}=0;#if this flag is set, this step will ignore suffixes gathered from previous steps, and restart accumulation
	$self->{substeps}=[];#list of subjobs, in order, that compose this step
	$self->{vars}={};#convenience variables
	$self->{var_keys}=[];
	$self->{isCrossJob}=0;#flag for whether job cross-compares samples
	#jobs that this job depends on (uses the output of) 
	#cannot have conflicting output declarations, 
	#each declared input variable must only be defined by one or the other parent step
	#most steps should only have 1 parent
	#$self->{parents}=[];#probably dont need this now that I'm using the graph implementation
	#jobs that are children of this job
	#$self->{children}=[];#ditto^
	bless($self, $class);
	return $self;
}

sub readTemplate {
	my $class =shift;
	my @lines=@_;
	my $newStep=$class->new();
	my @joblines;
	my ($type,$suffix);
	# read templates from lines in a file
	chomp(@lines);
	for my $line(@lines){
		given($line){
			when(/^#\S+$/){
				given($line){
					when(/^#&VAR:.+$/){
						if(!($line =~ m/^#&VAR:(\$.+)=(.+)$/)){die "improperly formed VAR line in template: $line\n"}
							#print "\t\tStep Variable Line: $line\n";
						if(defined($newStep->{vars}->{$1})){die "Defined variable $1 twice in one template\n";}
						$newStep->{vars}->{$1}=$2;
						push(@{$newStep->{var_keys}},$1);
						print STDERR "\t\tvariable \"$1\" set to \"$2\"\n";
					} 
					when(/^#&SUFFIX:(.+)$/) {
						#print "\t\tStep Suffix Line: $line\n";
						if(defined($suffix)){
							die "Job Suffix defined twice in template!\n";
						}
						$suffix=$1;
						print STDERR "\t\tsuffix: $suffix\n";
						$newStep->{suffix}=$suffix;
				
					} 
					when(/^#&TYPE:(.+)$/) {
						#print "\t\tStep Type Line: $line\n";
						if(defined($type)){
							die "Job Type defined twice in template!\n";
						}
						$type = $1;
						given(uc($1)){
							when (/SOLO/){
								$newStep->{isCrossJob}=0;
							}
							when (/CROSS/){
								$newStep->{isCrossJob}=1;
							}
							default {
								die "improperly formed TYPE line in template: $line\n"
							}
						}
						print STDERR "\t\ttype: $type, crossjob: $newStep->{isCrossJob}\n";
					}
					default {
						print STDERR "Comment Line: $line\n";
					}
				}
			}
			default {
				#not a comment, push into joblines for SJM template reading
				push (@joblines,$line);
				#print "job line: $line\n";
			}
		}
	}
	#print scalar(@joblines)," joblines\n";
	#print join("\n", @joblines);
	#parse the SJM lines now
	$newStep->parseSubJobs(@joblines);
	print STDOUT $newStep->toTemplateString();
	return $newStep;
}

sub parseSubJobs{
	my $self =shift;
	my @lines=@_;
	my $newSubstep;
	my($injob,$incmd,$cmd_done)=(0,0,0);
	for my $line(@lines){
		if($injob){
			if($incmd){
				given($line){
					when(/^\s*cmd_end\s*$/){
						$incmd=0;
					}
					default{
						#store line as a command if it isn't cmd_end
						push(@{$newSubstep->{cmd}}, $line);
					}
				}
			} else {#if($incmd)
				given($line){
					when(/^\s*job_begin\s*$/){
						die ("job_begin found after previous job_begin but not after job_end\n");
					}
					when(/^\s*job_end\s*$/){
						$injob=0;
						#TODO VERIFY VALIDITY!!!
					}
					when(/^\s*cmd_begin\s*$/){
						die ("job_begin found after previous job_begin but not after job_end\n");
					}
					when(/^\s*name\s+(\S+)\s*$/){
						defined($newSubstep->{name}) ? ( die("name defined twice in job template\n") ): ($newSubstep->{name}=$1);							
					}
					when(/^\s*memory\s+(\S+)\s*$/){
						defined($newSubstep->{memory}) ? ( die("memory defined twice in job template\n") ): ($newSubstep->{memory}=$1);
					}
					when(/^\s*queue\s+(\S+)\s*$/){
						defined($newSubstep->{queue}) ? ( die("queue defined twice in job template\n") ): ($newSubstep->{queue}=$1);
					}
					when(/^\s*module\s+(\S+)\s*$/){
						defined($newSubstep->{module}) ? ( die("module defined twice in job template\n") ): ($newSubstep->{module}=$1);
					}
					when(/^\s*directory\s+(\S+)\s*$/){
						defined($newSubstep->{directory}) ? ( die("module defined twice in job template\n") ): ($newSubstep->{directory}=$1);
					}						
					when(/^\s*status\s+(\S+)\s*$/){
						die("status should not be defined in templates!\n");
					}
					when(/^\s*id\s+(\S+)\s*$/){
						defined($newSubstep->{id}) ? ( die("id defined twice in job template\n") ): ($newSubstep->{id}=$1);
					}
					when(/^\s*cpu_usage\s+(\S+)\s*$/){
						defined($newSubstep->{cpu_usage}) ? ( die("cpu_usage defined twice in job template\n") ): ($newSubstep->{cpu_usage}=$1);
					}
					when(/^\s*wallclock\s+(\S+)\s*$/){
						defined($newSubstep->{wallclock}) ? ( die("wallclock defined twice in job template\n") ): ($newSubstep->{wallclock}=$1);
					}
					when(/^\s*memory_usage\s+(\S+)\s*$/){
						defined($newSubstep->{memory_usage}) ? ( die("memory_usage defined twice in job template\n") ): ($newSubstep->{memory_usage}=$1);
					}
					when(/^\s*swap_usage\s+(\S+)\s*$/){
						defined($newSubstep->{swap_usage}) ? ( die("swap_usage defined twice in job template\n") ): ($newSubstep->{swap_usage}=$1);
					}
					when(/^\s*cmd\s+(.+)\s*$/){
						if($cmd_done){die("cmd defined twice for job in template\n");}
						$cmd_done=1;
						push(@{$newSubstep->{cmd}}, $1);
					}
					when(/^\s*cmd_begin\s+(\S+)\s*$/){
						if($cmd_done){die("cmd defined twice for job in template\n");}
						$incmd=1;
					}
					default{
						die ("invalid line in template: $line\n");
					}
				}
			}
		} else {#if($injob)
			given($line){
				when(/^\s*job_begin\s*$/){
					$injob=1;
					$cmd_done=0;
					$newSubstep=$self->getNewSubStep();
				}
				when(/^\s*job_end\s*$/){
					die ("job_end did not follow job_begin\n");
				}
				when(/^\s*log_dir\s+(\S+)\s*$/){
					die ("log_dir should not be defined in templates!\n");
				}
				when(/^\s*order\s+(.+)\s*$/){
					my($parentjob,$childjob);
					given($line){
						when(/^\s*order\s*(\S+)\s*before\s*(\S+)\s*$/){
							$parentjob=$1;
							$childjob=$2;
						}
						when(/^\s*order\s*(\S+)\s*after\s*(\S+)\s*$/){
							$parentjob=$2;
							$childjob=$1;
						}
						default{
							die ("invalid order line in template: $line\n");
						}
					}
					print STDERR "setting depedency: $childjob after $parentjob\n";
					$self->addDependency($childjob,$parentjob);
				}
				default{
					die ("invalid line in template: $line\n");
				}
			}	
		}
	}
}



sub setAssume {
	my $self =shift;
	for my $substep(@{$self->{substeps}}){
		$substep->{status}="done";
	}
}

sub getNewSubStep{
	my $self = shift;
	my $newsubstep= PipelineSubStep->new($self);
	push (@{$self->{substeps}},$newsubstep);
	return $newsubstep;
}

sub addDependency {
	my $self =shift;
	my $child=shift;
	my $parent = shift;
	my ($parentfound,$childsubstep);
	for my $substep(@{$self->{substeps}}){
		if($substep->{name} eq $parent){
			$parentfound=1;
		} elsif($substep->{name} eq $child){
			$childsubstep=$substep;
		}
	}
	if(!$parentfound){die "No job exists with name: $parent\n";}
	if(!defined($childsubstep)){die "No job exists with name: $child\n";}
	push(@{$childsubstep->{order_after}},$parent);
}

sub toTemplateString{
	my $self=shift;
	my $str="";
	for my $v(@{$self->{var_keys}}){
		$str.="#&VAR:$v=$self->{vars}->{$v}\n";
	}
	$str.="#&SUFFIX:$self->{suffix}\n";
	if($self->{isCrossJob}){
		$str.="#&TYPE:CROSS\n";		
	} else {
		$str.="#&TYPE:SOLO\n";
	}
	for my $i(@{$self->{substeps}}) {
		$str.=$i->toTemplateString();		
	}
	return $str;
}

sub toString{
	my $self=shift;
	my $grouplbl=shift;
	if(!defined($grouplbl)){die "toString called without grouplbl variable\n";}
	my $cumsuffix = shift;
	if(!defined($cumsuffix)){die "toString called without cumsuffix variable\n";}
	my ($prefix,$prefix2);
	$prefix=shift;
	if(!defined($prefix)){die "toString called without prefix variable\n";}
	if($self->{isCrossJob}){
		$prefix2=shift;
		if(!defined($prefix2)){die "toString called on crossjob without prefix2 variable\n";}
	}else {$prefix2="";}
	#${AnalysisPipeline::SettingsLib}{"PREFIX"}=$prefix;
	#${AnalysisPipeline::SettingsLib}{"GROUPLBL"}=$grouplbl;
	my $str="";
	for my $i(@{$self->{substeps}}){
		if($self->{isCrossJob}){
			$str.=$i->toString($grouplbl,$cumsuffix,$prefix,$prefix2);
		} else {
			$str.=$i->toString($grouplbl,$cumsuffix,$prefix);	
		}		
	}
	return $str;
}
1;
	
package PipelineSubStep;#individual_SJM_JOB
use strict;
use warnings;
	#example job from a status file:
	#name PT5_RNA_BWA_SAMPE_TSRNA091711TCBL5
    #memory 10737418240 M
    #queue all.q
    #module EversonLabBiotools/1.0
    #directory /home/CAM/mgooch/Everson/Projects/Bladder/Pt5/RNA
    #status done
    #id 151327
    #cpu_usage 2704
    #wallclock 2596
    #memory_usage 1808490496
    #swap_usage 0
    #cmd /UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh bwa_run.sh TSRNA091711TCBL5
sub new {
	my $class = shift;
	my $self = {};
	$self->{name}= undef;
	$self->{subname}= undef;#used when defining multiple jobs that use same template, will be appended to name
	$self->{memory}= undef;
	$self->{queue}= undef;
	$self->{module}= undef;
	$self->{directory}= undef;
	$self->{status}= undef;#waiting,failed,done
	$self->{cmd}= [];#list of commands if only 1 member will output in single command mode
	#following not really needed to generate new jobs, but if parsing an SJM file, it will be good to have placeholders
	$self->{id}= undef;
	$self->{cpu_usage}= undef;
	$self->{wallclock}= undef;
	$self->{memory_usage}= undef;
	$self->{swap_usage}= undef;
	#list of jobnames that this job must wait for
	$self->{order_after}=[];
	$self->{parent}=shift;#DONE have this be added via a subroutine in the parent class, so this automatically gets supplied
	
	bless($self, $class);
	return $self;
}
sub getName {
	my $self = shift;
	my $str="";
	if(defined($self->{name})){
		if(defined($self->{subname})){
			$str.=$self->{name}."_".$self->{subname};
		} else {
			$str.=$self->{name};
		}
	}
	return $str;
}
sub toTemplateString {
	my $self = shift;
	my $str="";
	$str.="job_begin\n";
	if(defined($self->{name})){
		$str.="\tname ".$self->getName($str)."\n";
	}
	if(defined($self->{memory})){
		$str.="\tmemory ".$self->{memory}."\n";
	}
	if(defined($self->{queue})){
		$str.="\tqueue ".$self->{queue}."\n";
	}
	if(defined($self->{module})){
		$str.="\tmodule ".$self->{module}."\n";
	}
	if(defined($self->{directory})){
		$str.="\tdirectory ".$self->{directory}."\n";
	}
	if(defined($self->{status})){
		$str.="\tstatus ".$self->{status}."\n";
	}
	if(defined($self->{cmd})){
		my $numcmds;
		$numcmds=scalar(@{$self->{cmd}});
		given($numcmds){
			when(/0/){
				die "tried to create job template string when no commands defined for job!!\n";
			}
			when(/1/){
				$str.="\tcmd ".${$self->{cmd}}[0]."\n";
			}
			default{
				$str.="\tcmd_begin\n";
				for my $item(@{$self->{cmd}}){
					$str.="\t\t".$item."\n";
				}
				$str.="\tcmd_end\n";
			}
		}
	}
	$str.="job_end\n";
	if(defined($self->{order_after})){
		for my $item(@{$self->{order_after}}){
			$str.="order ".$self->getName($str)." after ".$item."\n";
		}
	}
	return $str;
}

sub toString {
	my $self=shift;
	my $grouplbl=shift;
	if(!defined($grouplbl)){die "PipelineSubStep toString called without grouplbl variable\n";}
	my $cumsuffix = shift;
	if(!defined($cumsuffix)){die "PipelineSubStep toString called without cumsuffix variable\n";}
	my ($prefix,$prefix2);
	$prefix=shift;
	if(!defined($prefix)){die "PipelineSubStep toString called without prefix variable\n";}
	if($self->{parent}->{isCrossJob}){
		$prefix2=shift;
		if(!defined($prefix2)){die "PipelineSubStep toString called on crossjob without prefix2 variable\n";}
	}else {$prefix2="";}
	
	return AnalysisPipeline::replaceVars($self->toTemplateString(),\$self,$grouplbl,$cumsuffix,$prefix,$prefix2);
}
1;