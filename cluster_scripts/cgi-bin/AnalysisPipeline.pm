#!/usr/bin/env perl
#these libs are defined so testing in windows with mobaxterm works.
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';

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
our %SettingsLib;
$SettingsLib{"PREFIX"}="";
$SettingsLib{"GROUPLBL"}="";
$SettingsLib{"SJM_FILE"}="";
#REST ARE OK FOR NOW
$SettingsLib{"HANDLER_SCRIPT"}="/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh";
$SettingsLib{"GENOME"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fa";
$SettingsLib{"BWAINDEX"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fa";
$SettingsLib{"BOWTIEINDEX"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE/ucsc.hg19";
$SettingsLib{"BOWTIE2INDEX"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE2/ucsc.hg19";
$SettingsLib{"DBSNP"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf";
$SettingsLib{"GENES"}="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf";
$SettingsLib{"TRANSCRIPTOME"}="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes";
$SettingsLib{"MODULEFILE"}="EversonLabBiotools/1.0";
$SettingsLib{"JOBQUEUE"}="all.q";
$SettingsLib{"MINQUAL"}=30;
$SettingsLib{"MAPQUAL"}=40;
$SettingsLib{"GENOME_TYPE"}="hg19";
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
$SettingsLib{"JAVA_RAM"}="33G";
#roughly 250,000 per GB
$SettingsLib{"MRECORDS"}=250,000*33;
$SettingsLib{"TARGET_BED"}="/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed";
$SettingsLib{"CURDIR"}=PipelineUtil::trim(abs_path(File::Spec->curdir()));
$SettingsLib{"BWA_RAM"}="10G";
$SettingsLib{"JAVA_JOB_RAM"}="50G";
$SettingsLib{"SHIMMER_RAM"}="20G";
$SettingsLib{"GENERIC_JOB_RAM"}="30G";
our %jobtemplates;#list of job templates that will be used for generating the jobSteps
our $jobNameGraph=Graph->new(directed=>1,refvertexed=>1);#graph of jobnames
our $jobGraph=Graph->new(directed=>1,refvertexed_stringified=>1);#graph of jobs
#method of output depends on options, 
#will run generator once for each set of inputs, 
#but may end up generating one or several jobfiles for each step or for the whole job.
#options will be: split_by_sample && split_by_step
#split_by_sample will not have any effect if a job unit pairs files across samples, 
#as there is no way to do this.
sub replaceVars{
	my $str=shift;
	my $search;
	my $replace;
	for my $key(keys(%SettingsLib)){
		$search='\$'.$key;
		$replace=$SettingsLib{$key};
		#print "search $search : replace $replace\n";
		$str=~s/$search/$replace/g;
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
	#TODO check if jobname is already defined / loaded
	#if not found, check if a template exists & load it
	my $path=TemplateDir();
	my $file=File::Spec->catfile($path,uc($step_name).'.sjt');
	unless (load_template($file)) {
		print STDERR "There is no template for step \"$step_name\" & it is not defined manually\n";
	}
}
sub load_template {
	my $filename=shift;
	print STDERR "\tloading template: $filename\n";
	unless (-e $filename){
		return 0;
	}
	#TODO load template
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
	$self->{inputs}={};
	#list of files this step creates
	#(only need to include files that will be used by other steps)
	$self->{outputs}={};
	$self->{substeps}=[];#list of subjobs, in order, that compose this step
	#jobs that this job depends on (uses the output of) 
	#cannot have conflicting output declarations, 
	#each declared input variable must only be defined by one or the other parent step
	#most steps should only have 1 parent
	$self->{parents}=[];
	#jobs that are children of this job
	$self->{children}=[];
	bless($self, $class);
	return $self;
}
sub toTemplateString{
	my $self=shift;
	my $str="";
	for my $i(@{$self->{substeps}}) {
		$str.=$i->toTemplateString();		
	}
	return $str;
}

sub toString{
	my $self=shift;
	my $prefix=shift;
	my $grouplbl=shift;
	my $sjm_file=shift;
	${AnalysisPipeline::SettingsLib}{"PREFIX"}=$prefix;
	${AnalysisPipeline::SettingsLib}{"GROUPLBL"}=$grouplbl;
	${AnalysisPipeline::SettingsLib}{"SJM_FILE"}=$sjm_file;
	my $str="";
	for my $i(@{$self->{substeps}}){
		$str.=$i->toString();		
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
		$str.="\tcmd ".$self->{cmd}."\n";
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
	my $self =shift;
	return AnalysisPipeline::replaceVars($self->toTemplateString());
}

sub parsejob {
	my $self = shift;
	my $stringarr= shift;
	my $string;
	$string=$$stringarr[0];
	$string=trim($string);
	if($string ne "job_begin"){
		return undef;#cannot parse from here
	}
	while (@{$stringarr}){
		$string=trim(shift (@{$stringarr} ) );
		$string=q($string=").$string.q(");
		eval $string;
		print STDERR  $string;
	}
}
1;