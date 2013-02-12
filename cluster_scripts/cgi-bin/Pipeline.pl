#!/usr/bin/env perl
use Cwd;
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Storable;
use SampleData;
use AnalysisPipeline;
use Switch;
use File::Basename;

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
						"copyfiles" => \$copyfiles, #specify this to force cp instead of ln -s
						"help|h" =>\$help);
if($help){
	ShowUsage();
}
if(!defined($copyfiles)){$copyfiles=0;}
print "copyfiles: $copyfiles\n";
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
	$assumeSteps[$i]=trim($assumeSteps[$i]);
}
print "# of steps to assume: ".scalar(@assumeSteps)."\n";


$pipeline=uc($pipeline);#forcing uppercase is a cheap way to ignore case of input -> requires all checked text to also be uppercase
@pipelineSteps=split("-",$pipeline);
for ($i=0;$i < scalar(@pipelineSteps);++$i ){
	$step=$pipelineSteps[$i];
	$step=trim($step);
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
		if($i==0){print STDERR " <---STARTING JOBS HERE\n";}
		print STDERR ("\n")
	}
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
sub FILTERBAM_Pipeline {}
#Analysis steps
sub VARIANTCALL_Pipeline {}
sub RNACUFF_Pipeline {}

# Trim both sides to remove leading/trailing whitespace
sub trim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/\s+$//;
	return $string;
}
