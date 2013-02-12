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
our $GROUPLBL="";
our $SJM_FILE="";
#REST ARE OK FOR NOW
our $HANDLER_SCRIPT="/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh";
our $GENOME="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fa";
our $BWAINDEX="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fa";
our $BOWTIEINDEX="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE/ucsc.hg19";
our $BOWTIE2INDEX="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE2/ucsc.hg19";
our $DBSNP="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf";
our $GENES="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf";
our $TRANSCRIPTOME="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes";
our $MINQUAL=30;
our $MAPQUAL=40;
our $GENOME_TYPE="hg19";
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
our $JAVA_RAM="33G";
#roughly 250,000 per GB
our $MRECORDS=250,000*33;
our $TARGET_BED="/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed";
our $CURDIR=PipelineUtil::trim(abs_path(File::Spec->curdir()));
our $BWA_RAM="10G";
our $JAVA_JOB_RAM="50G";
our $SHIMMER_RAM="20G";
our $GENERIC_JOB_RAM="30G";
our %jobtemplates;#list of job templates that will be used for generating the jobSteps
our $jobNameGraph=Graph->new(directed=>1,refvertexed=>1);#graph of jobnames
our $jobGraph=Graph->new(directed=>1,refvertexed_stringified=>1);#graph of jobs
#method of output depends on options, 
#will run generator once for each set of inputs, 
#but may end up generating one or several jobfiles for each step or for the whole job.
#options will be: split_by_sample && split_by_step
#split_by_sample will not have any effect if a job unit pairs files across samples, 
#as there is no way to do this.

sub parseAssume{
	my $string=shift;
	my @assume_vertices=parsePipeline($string);#store them to mark them "done" and then return them
	for my $vertex(@assume_vertices){
		#TODO mark done
	}
	return @assume_vertices; 
}

sub parsePipeline{
	my $string=shift;
	$string=PipelineUtil::trim($string);
	my @parents=@_;#=uniq @_;
	#print STDERR  "parsing: $string\n";
	#if(scalar(@parents)){print STDERR  "\tparents: @parents\n";}
	my @added_Vertices;#store them to return them
	my ($openparenpos,$closeparenpos,$paren_err)=getParenthesisPositions($string);
	my $parensub="";
	if($paren_err){die "INVALID FORMAT (parentheses error)\n";}
	if($openparenpos==0 && $closeparenpos>-1){
		$parensub=substr($string,$openparenpos+1,$closeparenpos-$openparenpos-1);
		my $rest=substr($string,$closeparenpos+1);
		my $parentstr;
		#my @parents;
		#print STDERR  "balanced parenthesis found from $openparenpos to $closeparenpos; contained: $parensub\n";
		if(charAt($rest,0) eq '['){
			my $end=index($rest,']');
			if($end != -1){
				$parentstr=substr($rest,1,$end-1);
				$rest=substr($rest,$end+1);
				push (@parents,split(',',$parentstr));
				#@parents=uniq @parents;
				#print "\tusing parents: @parents\n";
			}
		}
		if(charAt($rest,0) eq '-'){die "FORMAT ERROR (dash following parentheses)\n"};
		if(charAt($rest,0) eq ':'){$rest=substr($rest,1)};
		#print STDERR  "rest: $rest\n";
		my @commasplit=splitCommaNotInParens($parensub);
		for my $item (@commasplit){
			if(scalar(@parents)){
				push (@added_Vertices,parsePipeline($item,@parents));
			} else {
				push (@added_Vertices,parsePipeline($item));
			}
		}
		if(defined($rest) && length ($rest)){push (@added_Vertices,parsePipeline($rest));}
	} else {
		my $parentstr="";
		my $namestr="";
		#my $commapos=index($string,',');
		my $colonpos=index($string,':');
		my $dashpos=index($string,'-');
		#print STDERR "colonpos: $colonpos\n";
		#print STDERR "dashpos: $dashpos\n";
		if($colonpos == 0){die "INVALID FORMAT (colon at start of parse)\n";}
		if($dashpos == 0){die "INVALID FORMAT (dash at start of parse)\n";}
		if ($colonpos > 0 && ($colonpos < $dashpos || $dashpos <=0  ) ){
			$namestr=substr($string,0,$colonpos);#012
			my $rest=substr($string,$colonpos+1);
			#ADD
			parseBrackets($namestr,\$namestr,\@parents);
			addStep($namestr,@parents);
			push(@added_Vertices,$namestr);
			#print STDERR  ("COLON SEPARATOR -> namestr: $namestr\n");
			push(@added_Vertices,parsePipeline($rest));
		} elsif ($dashpos > 0 && ( $dashpos < $colonpos || $colonpos <=0 ) ){
			$namestr=substr($string,0,$dashpos);#012
			my $rest=substr($string,$dashpos+1);
			#print "parents before: @parents\n";
			parseBrackets($namestr,\$namestr,\@parents);
			#print "parents after: @parents\n";
			#ADD
			addStep($namestr,@parents);
			push(@added_Vertices,$namestr);
			#print STDERR ("DASH SEPARATOR -> namestr: $namestr\n");
			push(@added_Vertices,parsePipeline($rest,$namestr));
		} else {
			#print STDERR "string: $string\n";
			parseBrackets($string,\$namestr,\@parents);
			#$namestr=$string;
			if($namestr ne ""){
				#ADD
				addStep($namestr,@parents);
				push(@added_Vertices,$namestr);
			}
			#print STDERR "namestr: $namestr\n";
		}
	}
	return @added_Vertices;
}
sub parseBrackets{
	my $string=shift;
	my $namestr=shift;
	my $parents=shift;
	my $start=index($string,'[');
	my $end=index($string,']');
	my $parentstr;
	
	if($start > 0){
		if($end > 0){
			#print STDERR "string: $string\n";
			$parentstr=substr($string,$start+1,$end-$start-1);
			#print STDERR "parentstr: $parentstr\n";
			${$namestr}=substr($string,0,$start);
			#print STDERR "namestr: ${$namestr}\n";
			push (@{$parents},split(',',$parentstr));
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
		if(! $jobNameGraph->has_vertex($parent)){
			die("SYNTAX ERROR, Step \"$parent\" used as parent before it was defined\n");
		}
		if(! $jobNameGraph->has_edge($parent,$StepName)){
			$jobNameGraph->add_edge($parent,$StepName);
		}
		
	}
}
sub splitCommaNotInParens{
	my @splitresult;
	my $string=shift;
	#print STDERR "splitting: $string\n";
	my $parenlayer=0;
	my $char;
	my $badformat=0;
	my $word="";
	for(my $i=0;$i<length($string) && !$badformat;++$i){
		$char=charAt($string,$i);
		if($char eq '('){
			++$parenlayer;
		}elsif($char eq ')'){
			--$parenlayer;
			if($parenlayer==-1){$badformat=1;}
		}
		if($char eq ',' && $parenlayer == 0){
			push (@splitresult,$word);
			$word="";
		}else {
			$word.=$char;
		}
	}
	push (@splitresult,$word);
	if($badformat){
		die("INVALID FORMAT (parentheses error)\n");
	}
	return @splitresult;
}
sub getParenthesisPositions{
	my $string=shift;
	my (@positions)=(-1,-1,0);
	my $parenfound=0;
	my $parenlayer=0;
	my $char;
	my $badformat=0;
	my $done=0;
	for(my $i=0;$i<length($string) && !$done;++$i){
		$char=charAt($string,$i);
		if($char eq '('){
			if(!$parenfound){$positions[0]=$i;}
			$parenfound=1;
			++$parenlayer;
		}elsif($char eq ')'){
			if(!$parenfound){$badformat=1;$done=1;}
			--$parenlayer;
			if($parenlayer==-1){$badformat=1;$done=1;}
			if($parenfound && $parenlayer==0){$positions[1]=$i;$done=1;}
		}
	}
	if($badformat){
		@positions=(-1,-1,1)#no values and indicate error
	}
	return @positions;
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
sub test {
	my $t;
	$GROUPLBL="PT0";
	$t=PipelineUtil::SJM_JOB('BWA_ALN_FILE_1', $BWA_RAM, q(bwa aln -t 10 $BWAINDEX FILE_1.fq -f FILE_1.fq.aligned));
	#print STDERR  $t."\n";
	my $job=q(print STDERR ").$t.q(";);
	print STDERR  $job,"\n";
	$job =~ s/\n/\\n/g;
	print STDERR  $job,"\n";
	if(!defined(eval $job)){
		print STDERR  $@,"\n";
	} else {
		#print STDERR  $t,"\n";
	}
	#my $derp=q(print STDERR $BWA_RAM,"\n";);
	#eval $derp;
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
	$self->{substeps}=();#list of subjobs, in order, that compose this step
	#jobs that this job depends on (uses the output of) 
	#cannot have conflicting output declarations, 
	#each declared input variable must only be defined by one or the other parent step
	#most steps should only have 1 parent
	$self->{parents}=();
	#jobs that are children of this job
	$self->{children}=();
	bless($self, $class);
	return $self;
}
	
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
	$self->{memory}= undef;
	$self->{queue}= undef;
	$self->{module}= undef;
	$self->{directory}= undef;
	$self->{status}= undef;#waiting,failed,done
	$self->{cmd}= ();#list of commands if only 1 member will output in single command mode
	#following not really needed to generate new jobs, but if parsing an SJM file, it will be good to have placeholders
	$self->{id}= undef;
	$self->{cpu_usage}= undef;
	$self->{wallclock}= undef;
	$self->{memory_usage}= undef;
	$self->{swap_usage}= undef;
	$self->{dependencies}=();#list of jobnames that this job must wait for
	
	bless($self, $class);
	return $self;
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