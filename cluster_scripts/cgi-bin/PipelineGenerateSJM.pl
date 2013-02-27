#!/usr/bin/env perl
#these libs are defined so testing in windows with mobaxterm works.
use strict;
use warnings;
use feature 'switch';
given($^O){
	when(/cygwin/){
		use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
		use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
		use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
		use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
		use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';
	}
	when(/linux/){
		use lib '/UCHC/HPC/Everson_HPC/cluster_scripts/cgi-bin';
	}
}


use Cwd;
use Cwd 'abs_path';
use Getopt::Long qw(:config no_ignore_case bundling);
use Storable;
use SampleData;
use AnalysisPipeline;
use File::Basename;
use List::MoreUtils qw(uniq);

#make script args global
my $goodopts;
our ($pipeline,$assume,@assumeSteps,$listtxt,$pairstxt,$jobfile,@pipelineSteps,%StepsDefined,$copyfiles);
our $jobNameGraph=Graph->new(directed=>1,refvertexed=>1);#graph of jobnames
#DNA Pipeline
#align step
#filtering
#analysis
my $help=0;#indicates usage should be shown and nothing should be done
#TODO option for --splitSOLO , sjm generation will result in separate *.sjm files for each input file,
#TODO ^has no effect on crossjobs (change to join, split is default)
#TODO option for --splitSTEPS , sjm generation will result in separate *.sjm files for each step (Template)
#TODO ^above 2 can be combined to split generated sjm files across samples AND steps (change to join, split is default)
#TODO option for --splitCROSS, generate a separate sjm file for each pairing
#TODO ^ should only be used if cross step is set up so that any required SOLO substeps are in a 
#TODO separate template and run prior to the CROSS step; program will blindly assume all cross steps are truly crossed 
#TODO (thus it might run the same SOLO sub-commands more than once, resulting in conflicts)
my ($joinSOLO,$joinSTEPS,$splitCROSS)=(0,0,0);
$goodopts = GetOptions ("pipeline|P=s" => \$pipeline,	# list of steps to run IN ORDER
						"list|L=s"   => \$listtxt,	# list of files
						"pairs|p=s"  => \$pairstxt,	#file with list of sample pairs (only needed for steps that use more than 1 sample)
						"assumeSteps|A=s" => \$assume, #list of steps to assume were already run, assume order as well (acts like pipeline)
						"joinSamples|j" => \$joinSOLO,
						"joinSteps|J" => \$joinSTEPS,
						"splitCompares|S" => \$splitCROSS,
						"help|h" =>\$help);
#print "$joinSOLO, $joinSTEPS, $splitCROSS\n";
if($help){
	ShowUsage();
	exit (0);#being asked to show help isn't an error
}
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
@assumeSteps=parseAssume($assume);
$pipeline=uc($pipeline);#forcing uppercase is a cheap way to ignore case of input -> requires all checked text to also be uppercase
@pipelineSteps=parsePipeline($pipeline);
if(scalar(@assumeSteps) + scalar(@pipelineSteps) ==0){ShowUsage ("no pipeline specified!\n");}
print STDERR "Step Graph: $jobNameGraph\n";

exit( main(scalar(@ARGV),\@ARGV) );

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
	#TODO can traverse graph like this: 
	#@sinks = $g->sink_vertices()
	#@sources = $g->source_vertices()
	#@parents = $g->predecessors($v)
	#@children = $g->successors($v)
	#TODO figure out best way to traverse graph
	#any 1 step(per-sample or pair of samples) should probably only be allowed to have at most 2 parents (for CROSSJOBS) and 1 parent (for SOLOJOBS)
	#start at sources, fill in all required info @ one level THEN handle children by stripping sources off of a copied graph so as not to wreck the original
	#will ensure that all required info is available before successors are handled.   
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

sub addStep{
	my $StepName=shift;
	my @parents=uniq @_;
	print STDERR "Adding Step: $StepName with parents: @parents\n";
	if(! $jobNameGraph->has_vertex($StepName)){
		$jobNameGraph->add_vertex($StepName);
		AnalysisPipeline::require_jobdef($StepName);
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

sub charAt { return substr($_[0],$_[1],1); }
