#!/usr/bin/env perl
use Cwd;
use strict;
use Getopt::Long;
use SampleData;
use Storable;
#switches
our($stats,$exec,$help,$tophat,$cufflinks,$cpus,$trim,$untrim);
$stats=1;
$exec=1;
$help=0;
$tophat=1;
$cufflinks=1;
$trim=1;
$untrim=1;
GetOptions( "stats!"=> \$stats,
	    "exec!"=>\$exec,
	    "tophat!"=>\$tophat,
	    "cufflinks!"=>\$cufflinks,
	    "help"=>\$help,
	    "cpus=i"=>\$cpus,
	    "trim!"=> \$trim,
	    "untrim!"=> \$untrim
);
if(!defined($cpus)){
#print "CPUS not defined\n";
$cpus=2;
}#else{print "CPUS:$cpus\n";}
our($projdir,$batchfile,$wdir,%files,$TrimDir,$UntrimDir,$TOPDIR,$CUFFDIR,$FQ);

$FQ="FASTQ";
$TrimDir="Trimmed";
$UntrimDir="Untrimmed";
$TOPDIR="Tophat";
$CUFFDIR="Cufflinks";

#stages suffix
our($trimsuffix,$tophatsuffix,$cufflinksuffix,$alignsuffix,$LSort);

$trimsuffix= ".trimmed.filtered";
$tophatsuffix=".tophat";
$cufflinksuffix=".cufflinks";
$alignsuffix="/accepted_hits.bam";
$LSort="LengthSort";

our($genome,$index,$indexpath);
$genome="Sequence/WholeGenomeFasta/genome.fa";
$index="Sequence/BowtieIndex/genome";
$indexpath="/UCHC/Everson/tools/igenomes/Homo_sapiens/UCSC/hg19/";
our($GTF);
$GTF=$indexpath."Annotation/Genes/genes.gtf";


#first end or only end suffix
our($suffix,$suffix2,$suffix3);
$suffix="_1_sequence.fq";
#second end suffix
$suffix2="_2_sequence.fq";
#combined suffix
$suffix3="_1_2_sequence.fq";

our($arrayid);
#start here
if(defined($ENV{PBS_ARRAYID}))
{$arrayid=$ENV{PBS_ARRAYID}+0;}
else
{$arrayid=-1;}

if($help){#print usage
	my ($usage);
	$usage=$0." <batch_file>.\n";
	$usage.="<batch_file> defaults to \"./files.txt\"\n";
	$usage.="Options\n";
	$usage.="--nostats:    | Skip generation of alignment stats\n";
	$usage.="--noexec:     | Print commands but don't execute them\n";
	$usage.="--help:       | Display this help information\n";
	print $usage;
	exit(0);
}
#get current directory
$projdir= getcwd();
$wdir='workdir';

#print $projdir."\n";

#Read Batch File
if(@ARGV == 0){
	$batchfile="files.txt";
} elsif(@ARGV == 1){
	$batchfile=$ARGV[0];
} else{
	die "Wrong Number of Arguments to script\n";
}
print "\n";
%files=%{ Storable::dclone(SampleData::readbatch($batchfile)) };
#keys to the sample information hash
our(@keys);
@keys=sort(keys(%files) );
mkdirs();
if($arrayid<0)
{
	print "Running in Single Machine Mode\n";
	foreach(@keys)
	{
	#run analysis script on files
	$tophat ? tophat($_) : print "Skipping tophat Step\n";
	$cufflinks ? cufflinks($_) : print "Skipping Annotation Count Step\n";
	#get stats on alignment
	$stats ? getstats($_) : print "Skipping Statistics Generation Step\n";
	}
}else{
	print "Running in Cluster Job Array Mode\n";
	if(!defined($keys[$arrayid])){die "Array ID does not map to a Sample ID!\n";}
	#run analysis script on files
	$tophat ? tophat($keys[$arrayid]) : print "Skipping tophat Step\n";
	$cufflinks ? cufflinks($keys[$arrayid]) : print "Skipping Annotation Count Step\n";
	#get stats on alignment
	$stats ? getstats($keys[$arrayid]) : print "Skipping Statistics Generation Step\n";
} 
exit (0);

#should probably add handling of different types of zips in the future (ex: tar.gz, *.zip, *.rar)
sub tophat
{
	my($t,$samp);
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	$samp=$_[0];
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		if($untrim)
		{
			if($t->{PAIRED})
			{
				issuecmd("tophat -p $cpus -r 20 --GTF $GTF -o $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$suffix3$tophatsuffix $indexpath$index $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2");
			} else {
				issuecmd("tophat -p $cpus -r 20 --GTF $GTF -o $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$suffix$tophatsuffix $indexpath$index $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix");
			}
		}
		if($trim)
		{
			if($t->{PAIRED})
			{
				issuecmd("tophat -p $cpus -r 20 --GTF $GTF -o $projdir/$wdir/$TrimDir/$TOPDIR/$samp$suffix3$trimsuffix$tophatsuffix $indexpath$index $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix $projdir/$wdir/$TrimDir/$LSort/$samp$suffix2$trimsuffix");
			} else {
				issuecmd("tophat -p $cpus -r 20 --GTF $GTF -o $projdir/$wdir/$TrimDir/$TOPDIR/$samp$suffix$trimsuffix$tophatsuffix $indexpath$index $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix");
			}
		}
	}
}

sub cufflinks
{

	my($t,$samp);
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	$samp=$_[0];
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		if($untrim)
		{
			if($t->{PAIRED})
			{
				issuecmd("cufflinks --GTF-guide $GTF -o $projdir/$wdir/$UntrimDir/$CUFFDIR/$samp$suffix3$cufflinksuffix -q --no-update-check -I 300000 -F 0.050000 -j 0.050000 -p $cpus --frag-bias-correct $indexpath$genome $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$suffix3$tophatsuffix/accepted_hits.bam");
			} else {
				issuecmd("cufflinks --GTF-guide $GTF -o $projdir/$wdir/$UntrimDir/$CUFFDIR/$samp$suffix$cufflinksuffix -q --no-update-check -I 300000 -F 0.050000 -j 0.050000 -p $cpus --frag-bias-correct $indexpath$genome $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$suffix$tophatsuffix/accepted_hits.bam");
			}
		}
		if($trim)
		{
			if($t->{PAIRED})
			{
				issuecmd("cufflinks --GTF-guide $GTF -o $projdir/$wdir/$TrimDir/$CUFFDIR/$samp$suffix3$trimsuffix$cufflinksuffix -q --no-update-check -I 300000 -F 0.050000 -j 0.050000 -p $cpus --frag-bias-correct $indexpath$genome $projdir/$wdir/$TrimDir/$TOPDIR/$samp$suffix3$trimsuffix$tophatsuffix/accepted_hits.bam");
			} else {
				issuecmd("cufflinks --GTF-guide $GTF -o $projdir/$wdir/$TrimDir/$CUFFDIR/$samp$suffix$trimsuffix$cufflinksuffix -q --no-update-check -I 300000 -F 0.050000 -j 0.050000 -p $cpus --frag-bias-correct $indexpath$genome $projdir/$wdir/$TrimDir/$TOPDIR/$samp$suffix$trimsuffix$tophatsuffix/accepted_hits.bam");
			}
		}
	}
}

sub getstats
{
	my($t,$s,$samp);
	$samp=$_[0];
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	if(defined($files{$samp}))
	{	$t=$files{$samp};
		if($t->{PAIRED}){$s=$suffix3;}else{$s=$suffix;}
		if($untrim)
		{
			issuecmd("samtools index $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$s$tophatsuffix$alignsuffix");
			issuecmd("samtools idxstats $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$s$tophatsuffix$alignsuffix > $projdir/$wdir/$UntrimDir/$TOPDIR/$samp$s$tophatsuffix/$samp$s".".tophat_align_stats.txt");
		}
		if($trim)
		{
			issuecmd("samtools index $projdir/$wdir/$TrimDir/$TOPDIR/$samp$s$trimsuffix$tophatsuffix$alignsuffix");
			issuecmd("samtools idxstats $projdir/$wdir/$TrimDir/$TOPDIR/$samp$s$trimsuffix$tophatsuffix$alignsuffix > $projdir/$wdir/$TrimDir/$TOPDIR/$samp$s$trimsuffix$tophatsuffix/$samp$s$trimsuffix".".tophat_align_stats.txt");
		}
	}
}

sub issuecmd
{
	if(@_ != 1){die "wrong number of args to issuecmd (".scalar(@_).")"};
	print($_[0]."\n\n");
	if($exec){system($_[0]."\n");}
}

sub mkdirs
{

	if($untrim)
	{
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$TOPDIR");
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$CUFFDIR");
	}
	if($trim)
	{
		issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$TOPDIR");
		issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$CUFFDIR");
	}
}
