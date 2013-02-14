#!/usr/bin/env perl
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';

use strict;
use warnings;
use Cwd;
use Cwd 'abs_path';
use Getopt::Long qw(:config no_ignore_case bundling);
use Storable;
use SampleData;
use AnalysisPipeline;
use feature qw/switch/;
use File::Basename;
my $goodopts;
our ( @inputOpts, @outputOpts, $templatename, @subjobOpts, $help );
our( @jobs ,$template);
$template=PipelineStep->new();
$goodopts = GetOptions(
	"input|I=s"    => \@inputOpts,
	"output|O=s"   => \@outputOpts,
	"template|T=s" => \$templatename,
	"subjob|S=s"   => \@subjobOpts,
	"help|h"       => \$help
);
my $showusage=0;

if(!defined($templatename)){
	print STDERR "must provide a template name\n";$showusage=1;
}else{
	#print STDERR "template: $templatename\n";
}
if(scalar(@inputOpts)+scalar(@outputOpts) == 0){
	print STDERR "Must have at least 1 input or output\n";$showusage=1;
} else {
	if(!parseIOPuts($template->{inputs},@inputOpts)){
		print STDERR "problem parsing inputs\n";$showusage=1;
	} else {
		#print "inputs: @inputOpts\n";
	}
	if(!parseIOPuts($template->{outputs},@outputOpts)){
		print STDERR "problem parsing outputs\n";$showusage=1;
	} else {
		#print "outputs: @outputOpts\n";
	}
}
if(!parseSubjobs($template,@subjobOpts)){
	print STDERR "Problem parsing subjobs\n";$showusage=1;
} else {
	#print STDERR "subjobOpts: @subjobOpts\n";
}
#print $template->toTemplateString();
#print $template->toString('prefix','grouplbl','sjm_file');
sub parseIOPuts{
	#TODO make it so arguments get read in a way that helps first job gets its input from Pipeline.pl arguments
	#TODO and the rest can use output values of previous jobs
	my $templateio=shift;
	my @ioputs=@_;
}
sub parseSubjobs{
	my $template=shift;
	my @subjobOpts=@_;
	#print "template ".$template,"\n";
	for my $opt(@subjobOpts){
		push (@{$template->{substeps}},parseSubJob($opt));
	}
	return 1;
}

sub parseSubJob {
	my $opt=shift;
	my %subjobvars;
	my $subjob=PipelineSubStep->new();
	my @commasplit=split(',',$opt);
	for my $commaItem(@commasplit){
		my @equalsplit=split('=',$commaItem);
		if(scalar(@equalsplit) != 2){die "invalid argument syntax! should have 2 elements separated by '=', have: ".scalar(@equalsplit)."\n";}
		#print STDERR "$equalsplit[0] = $equalsplit[1]\n";
		if($equalsplit[0] eq "order_after"){
			my @arr=split(':',$equalsplit[1]);
			$subjob->{$equalsplit[0]}=\@arr;
		} else {
			$subjob->{$equalsplit[0]}=$equalsplit[1];
		}
		if(!defined($subjob->{module})){$subjob->{module}=q($MODULEFILE)};
		if(!defined($subjob->{directory})){$subjob->{directory}=q($CURDIR)}
		if(!defined($subjob->{queue})){$subjob->{queue}=q($JOBQUEUE)}
	}
	return $subjob;
}