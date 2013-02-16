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
use FileHandle;
my $goodopts;
our ( $suffix, $templatename, @subjobOpts, $clearsuffixes, @vars, $cross, $help );
our( @jobs ,$template);
$template=PipelineStep->new();
$goodopts = GetOptions(
	"variable|V=s"      => \@vars, #define convenience variables to replace first
	"clearsuffixes|C" => \$clearsuffixes, #setting this flag indicates that this step should completely rename its output, ignoring accumulated suffixes and restarting the accumulation.
	"suffix|S=s"      => \$suffix, #this suffix should be carried over into filenames using $ADJPREFIX by appending accumulated suffixes to $PREFIX
	"template|T=s"    => \$templatename,
	"subjob|J=s"      => \@subjobOpts,
	"cross|c"      => \$cross,
	"help|h"          => \$help
);
my $showusage=0;
if(!defined($cross)){$cross=0;}
$template->{isCrossJob}=$cross;
if(!defined($templatename)){
	print STDERR "must provide a template name\n";$showusage=1;
}else{
	#print STDERR "template: $templatename\n";
}
if(!defined($suffix)){
	$suffix="";
}
$template->{suffix}=$suffix;
#print "suffix $template->{suffix}\n"; 
if(!defined($clearsuffixes)){
	$clearsuffixes=0;
}
$template->{clearsuffixes}=$clearsuffixes;
if(!parseSubjobs($template,@subjobOpts)){
	print STDERR "Problem parsing subjobs\n";$showusage=1;
} else {
	#print STDERR "subjobOpts: @subjobOpts\n";
}
parseVars($template,@vars);
#print $template->toTemplateString();
#print $template->toString('prefix','grouplbl','sjm_file');
my $path=AnalysisPipeline::TemplateDir();
my $file=File::Spec->catfile($path,uc($templatename).'.sjt');
my $fh = FileHandle->new("> $file");
print $fh $template->toTemplateString();
$fh->close();

#print "\n\n";
#print $template->toString("groupLBL",".cumsuffix","prefix");

sub parseVars {
	my $template=shift;
	my @vars=@_;
	my @eqsplit;
	for my $var(@vars){
		@eqsplit=split('=',$var);
		if(scalar(@eqsplit!=2)){die "Incorrect syntax for var definition: $var\n";}
		if(defined($template->{vars}->{$eqsplit[0]})){die "defined same var twice: $eqsplit[0]\n";}
		$template->{vars}->{$eqsplit[0]}=$eqsplit[1];
	}
}

sub parseSubjobs{
	my $template=shift;
	my @subjobOpts=@_;
	#print "template ".$template,"\n";
	my $substep;
	for my $opt(@subjobOpts){
		$substep=$template->getNewSubStep();
		parseSubJob($opt,\$substep);
	}
	return 1;
}

sub parseSubJob {
	my $opt=shift;
	my $subjob=shift;
	my %subjobvars;
	my @commasplit=split(',',$opt);
	for my $commaItem(@commasplit){
		my @equalsplit=split('=',$commaItem);
		if(scalar(@equalsplit) != 2){die "invalid argument syntax! should have 2 elements separated by '=', have: ".scalar(@equalsplit)."\n";}
		#print STDERR "$equalsplit[0] = $equalsplit[1]\n";
		if($equalsplit[0] eq "order_after"){
			my @arr=split(':',$equalsplit[1]);
			${$subjob}->{$equalsplit[0]}=\@arr;
		} else {
			${$subjob}->{$equalsplit[0]}=$equalsplit[1];
		}
		if(!defined(${$subjob}->{module})){${$subjob}->{module}=q($MODULEFILE)};
		if(!defined(${$subjob}->{directory})){${$subjob}->{directory}=q($CURDIR)}
		if(!defined(${$subjob}->{queue})){${$subjob}->{queue}=q($JOBQUEUE)}
	}
	return $subjob;
}