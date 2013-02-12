#!/usr/bin/env perl
#these libs are defined so testing in windows with mobaxterm works.
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';

use strict;
use warnings;
use Cwd;
use Cwd 'abs_path';
use Getopt::Long qw(:config no_ignore_case bundling);
use Storable;
use SampleData;
use AnalysisPipeline;
use Switch;
use File::Basename;

use Graph;


#make script args global
my $goodopts;
our ($pipeline,$assume,@assumeSteps,$listtxt,$pairstxt,$jobfile,@pipelineSteps,%StepsDefined,$copyfiles);
#DNA Pipeline
#align step
#filtering
#analysis
my $help=0;#indicates usage should be shown and nothing should be done
my $usage="";
$goodopts = GetOptions ("pipeline|P=s" => \$pipeline,	# list of steps to run IN ORDER
						"list|L=s"   => \$listtxt,	# list of files
						"pairs|p=s"  => \$pairstxt,	#file with list of sample pairs (only needed for steps that use more than 1 sample)
						"assumeSteps|A=s" => \$assume, #list of steps to assume were already run, assume order as well (acts like pipeline)
						#"copyfiles" => \$copyfiles, #specify this to force cp instead of ln -s
						"help|h" =>\$help);
#how to define jobs for resolving file dependencies
#steps separated by ':' imply nothing about linkage, assume no link unless otherwise specified
#steps separated by '-' imply that JOBL is parent of JOBR
#STEP1-STEP2-STEP3

#can provide explicit parent-list by putting parent steps into square brackets and separating with ','
#parent step name must have been defined previously in a left-to-right manner
#examples:
#STEP1:STEP2[STEP1]-STEP3 or 
#STEP1:STEP2:STEP3[STEP1,STEP2] or 
#STEP1:STEP2[STEP1]:STEP3[STEP2] (equivalent to STEP1-STEP2-STEP3)

#multiple steps that are the children of a previous step can be combined into a parenthesis and separated by ','
#all subsequent linking should be done either inside the parenthesis or by separating with : and continuing definitions
#examples: 
#STEP1-(STEP2,STEP3) <- both steps 2 and 3 are children of step1 but have no relation to each other 
#STEP1-(STEP2_1-STEP2_2,STEP3_1-STEP3_2) <- STEP2_1 and STEP3_1 are children of STEP1, each has its own child
#STEP1-(STEP2,STEP3):STEP4[STEP3]
#STEP1:(STEP2,STEP3)[STEP1]:STEP4[STEP3] <-implies that both STEP2 and STEP3 are dependent on STEP1 and that STEP4 follows STEP3
#STEP1:(STEP2,STEP3-STEP4)[STEP1]  <- same as immediately previous example

#if assuming steps, pipeline steps can refer to assumed steps as their parents
#these definitions will be read left-to-right, any unresolvable situation will result in an error
#with these rules it should not be possible, but just in case: NO CIRCULAR DEPENDENCIES 
#obvious the above rules imply that step names cannot contain any of these: -()[]:

#TODO implement the above system
#for now going with '-'
if($help){
	ShowUsage();
}
#if(!defined($copyfiles)){$copyfiles=0;}
#print "copyfiles: $copyfiles\n";
if(!defined($pairstxt)){$pairstxt="./pairs.txt";}
print STDERR "pairs: \"$pairstxt\"\n";
if(!defined($listtxt)){$listtxt="./files.txt";}
print STDERR "list: \"$listtxt\"\n";
if(!defined($assume)){$assume="";}#assume is allowed to be blank if pipeline has values
print STDERR "assume: \"$assume\"\n";
if(!defined($pipeline)){$pipeline="";}#pipeline is allowed to be blank if assume has values
print STDERR "pipeline: \"$pipeline\"\n";

my ($i,$step);


$assume=uc($assume);#forcing uppercase is a cheap way to ignore case of input -> requires all checked text to also be uppercase
@assumeSteps=split("-",$assume);
for ($i=0;$i < scalar(@assumeSteps);++$i ){
	$assumeSteps[$i]=PipelineUtil::trim($assumeSteps[$i]);
}
print "# of steps to assume: ".scalar(@assumeSteps)."\n";


$pipeline=uc($pipeline);#forcing uppercase is a cheap way to ignore case of input -> requires all checked text to also be uppercase
@pipelineSteps=split("-",$pipeline);
for ($i=0;$i < scalar(@pipelineSteps);++$i ){
	$step=$pipelineSteps[$i];
	$step=PipelineUtil::trim($step);
	$pipelineSteps[$i]=$step;
}
print "# of steps to run: ".scalar(@pipelineSteps)."\n";
if(scalar(@assumeSteps) + scalar(@pipelineSteps) ==0){ShowUsage ("no pipeline specified!\n");}
DefineBuiltInSteps();
#TODO allow defining custom steps, not a super-high priority

exit( main(scalar(@ARGV),\@ARGV) );

sub DefineBuiltInSteps {
	#%StepsDefined#Store all defined pipelinesteps in this hash in a name=>object fashion
}

sub main {
	my $argc=shift;
	my @argv=@{$_[0]};
	shift;
	my ($step,$item);
	$item=0;
	for (my $i = 0 ; $i < scalar(@assumeSteps); ++$i ) {
		$step=$assumeSteps[$i];
		++$item;
		print STDERR ("Step $item: $step\n");
	}
	for (my $i = 0 ; $i < scalar(@pipelineSteps); ++$i ){
		$step=$pipelineSteps[$i];
		++$item;
		print STDERR ("Step $item: $step");
		if($i==0){print STDERR " <---STARTING JOBS HERE";}
		print STDERR ("\n")
	}
	#example of how to use variables in a template using eval:
	#my $derp=q(print "arg count: $argc, arguments: @argv");
	#eval $derp;
	#print "${PipelineStep::CURDIR}\n";
	
	return 0;
}

sub ShowUsage {
	my $errmsg=shift;
	my $scriptname=basename($0);
	my $usage="Usage: $scriptname [options]\n";
	if(!defined($errmsg)||$errmsg eq ""){
		$errmsg="";
	} else {
		$errmsg.="\n";
	}
	print STDERR "$errmsg$usage\n";
	exit(1);
}

#ALIGNMENT OPTIONS
#sub BOWTIE2_ALIGN_Pipeline {}#TODO add option to use bowtie2
sub BWA_ALIGN_Pipeline {}
sub TOPHAT_ALIGN_Pipeline {}
#Preparatory steps (filtering, sorting, reworking BAM file for requirements of tools)
sub GATK_PREP_Pipeline {}
sub FILTER_READS_Pipeline {}
#Analysis steps
sub CALL_VARIANTS_Pipeline {}
sub RNACUFF_Pipeline {}
