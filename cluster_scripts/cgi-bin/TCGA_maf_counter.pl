use strict;
use warnings;
use Cwd;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling);
use List::MoreUtils qw(uniq);
my $help=0;#indicates usage should be shown and nothing should be done
my ($illuminaFile,$solidFile,$opts);
my ($countGene,$countPatient,$countMutType)= (0) x 3;

$opts = GetOptions ("Illumina|f=s" => \$illuminaFile,	# path to illumina data
						"Solid|F=s"   => \$solidFile,	# path to solid data
						"countGene|G" => \$countGene, #list of steps to assume were already run, assume order as well (acts like pipeline)
						"countPatient|P" => \$countPatient,
						"countMutType|M" => \$countMutType,
						"help|h" =>\$help);
#print "$joinSOLO, $joinSTEPS, $splitCROSS\n";
if($help){
	ShowUsage();
	exit (0);#being asked to show help isn't an error
}
if(((not defined($illuminaFile)) and (not defined($solidFile))) or (length($illuminaFile) == 0 and length($solidFile) == 0)){
	ShowUsage("must provide at least one of the MAF files");
}
if (not($countGene or $countPatient or $countMutType)){
	ShowUsage("must choose at least one of the count options");
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