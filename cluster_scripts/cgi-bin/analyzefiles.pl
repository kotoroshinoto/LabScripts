#!/usr/bin/perl
use Cwd;
use strict;
use Getopt::Long;
use SampleData;
use Storable;
#switches
our($stats,$exec,$help,$align,$compare,$bwaaln,$cpus,$trim,$untrim);
$stats=1;
$exec=1;
$help=0;
$align=1;
$compare=1;
$bwaaln=1;
$trim=1;
$untrim=1;
GetOptions( "stats!"=> \$stats,
	    "exec!"=>\$exec,
	    "align!"=>\$align,
	    "compare!"=>\$compare,
	    "help"=>\$help,
	    "bwaaln!"=>\$bwaaln,
	    "trim!"=>\$trim,
	    "untrim!"=>\$untrim,
	    "cpus=i"=>\$cpus);
if(!defined($cpus)){
#print "CPUS not defined\n";
$cpus=2;
}#else{print "CPUS:$cpus\n";}
our($projdir,$batchfile,$wdir,%files,$FQ,$ALN,$SAM,$BAM,$STATS);
#stages suffix
our($donesuffix,$trimsuffix,$alignsuffix,$samsuffix,$bamsuffix,$sortsuffix,$TrimDir,$UntrimDir,$LSort);
$trimsuffix= ".trimmed.filtered";
$alignsuffix=".aligned";
$samsuffix=  ".aligned.sam";
$sortsuffix= ".aligned.sort";
$bamsuffix=  ".aligned.sort.bam";

$FQ="FASTQ";
$ALN="ALN";
$SAM="SAM";
$BAM="BAM";
$STATS="ALIGN_STATS";
$TrimDir="Trimmed";
$UntrimDir="Untrimmed";
$LSort="LengthSort";


$donesuffix=$sortsuffix;

our($genome,$index,$indexpath);
$genome="Sequence/WholeGenomeFasta/genome.fa";
$index="Sequence/BWAIndex/genome.fa";
$indexpath="/UCHC/Everson/tools/igenomes/Homo_sapiens/UCSC/hg19/";


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
	#print "bwaaln: $bwaaln\n";
	$align ? align($_) : print "Skipping Alignment Step\n";
	$compare ? compare_to_annotations($_) : print "Skipping Annotation Count Step\n";
	#get stats on alignment
	$stats ? getstats($_) : print "Skipping Statistics Generation Step\n";
	}
}else{
	print "Running in Cluster Job Array Mode\n";
	if(!defined($keys[$arrayid])){die "Array ID does not map to a Sample ID!\n";}
	#run analysis script on files
	$align ? align($keys[$arrayid]) : print "Skipping Alignment Step\n";
	$compare ? compare_to_annotations($keys[$arrayid]) : print "Skipping Annotation Count Step\n";
	#get stats on alignment
	$stats ? getstats($keys[$arrayid]) : print "Skipping Statistics Generation Step\n";
} 
exit (0);

#should probably add handling of different types of zips in the future (ex: tar.gz, *.zip, *.rar)
sub align
{
	my($t,$samp);
	$samp=$_[0];
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		if($untrim){
			$bwaaln ? issuecmd("bwa aln -t $cpus $indexpath$index $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix -f $projdir/$wdir/$UntrimDir/$ALN/$samp$suffix$alignsuffix") : print "skipping trimmed bwa aln step!\n";
			if($t->{PAIRED})
			{
				$bwaaln ? issuecmd("bwa aln -t $cpus $indexpath$index $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2 -f $projdir/$wdir/$UntrimDir/$ALN/$samp$suffix2$alignsuffix") : print "skipping bwa aln step for second file\n";
				#-i $projdir/$wdir/$samp"."_id -m $projdir/$wdir/$samp"."_sm -l $projdir/$wdir/$samp"."_lb
				issuecmd("bwa sampe -P $indexpath$index $projdir/$wdir/$UntrimDir/$ALN/$samp$suffix$alignsuffix $projdir/$wdir/$UntrimDir/$ALN/$samp$suffix2$alignsuffix $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2 -f $projdir/$wdir/$UntrimDir/$SAM/$samp$suffix3$samsuffix");
#				Usage:   bwa sampe [options] <prefix> <in1.sai> <in2.sai> <in1.fq> <in2.fq>
#
#				Options: -a INT   maximum insert size [500]
#				         -o INT   maximum occurrences for one end [100000]
#				         -n INT   maximum hits to output for paired reads [3]
#				         -N INT   maximum hits to output for discordant pairs [10]
#				         -c FLOAT prior of chimeric rate (lower bound) [1.0e-05]
#				         -f FILE  sam file to output results to [stdout]
#				         -r STR   read group header line such as `@RG\tID:foo\tSM:bar' [null]
#				         -P       preload index into memory (for base-space reads only)
#				         -s       disable Smith-Waterman for the unmapped mate
#				         -A       disable insert size estimate (force -s)
#	
#				Notes: 1. For SOLiD reads, <in1.fq> corresponds R3 reads and <in2.fq> to F3.
#				       2. For reads shorter than 30bp, applying a smaller -o is recommended to
#				          to get a sensible speed at the cost of pairing accuracy.
			} else {
				#-i $projdir/$wdir/$samp"."_id -m $projdir/$wdir/$samp"."_sm -l $projdir/$wdir/$samp"."_lb
				issuecmd("bwa samse $indexpath$index $projdir/$wdir/$UntrimDir/$ALN/$samp$suffix$alignsuffix $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix -f $projdir/$wdir/$UntrimDir/$SAM/$samp$suffix$samsuffix");
				#Usage: bwa samse [-n max_occ] [-f out.sam] [-r RG_line] <prefix> <in.sai> <in.fq>
			}
		}
		if($trim)
		{
			$bwaaln ? issuecmd("bwa aln -t $cpus $indexpath$index $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix -f $projdir/$wdir/$TrimDir/$ALN/$samp$suffix$trimsuffix$alignsuffix") : print "skipping bwa aln step!\n";
			if($t->{PAIRED})
			{
				$bwaaln ? issuecmd("bwa aln -t $cpus $indexpath$index $projdir/$wdir/$TrimDir/$LSort/$samp$suffix2$trimsuffix -f $projdir/$wdir/$TrimDir/$ALN/$samp$suffix2$trimsuffix$alignsuffix") : print "skipping bwa aln step for second file\n";
				issuecmd("bwa sampe -P $indexpath$index $projdir/$wdir/$TrimDir/$ALN/$samp$suffix$trimsuffix$alignsuffix $projdir/$wdir/$TrimDir/$ALN/$samp$suffix2$trimsuffix$alignsuffix $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix $projdir/$wdir/$TrimDir/$LSort/$samp$suffix2$trimsuffix -f $projdir/$wdir/$TrimDir/$SAM/$samp$suffix3$trimsuffix$samsuffix");
			} else {
				issuecmd("bwa samse $indexpath$index $projdir/$wdir/$TrimDir/$ALN/$samp$suffix$trimsuffix$alignsuffix $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix -f $projdir/$wdir/$TrimDir/$SAM/$samp$suffix$trimsuffix$samsuffix");
			}
		}
	}
}

sub compare_to_annotations
{

	my($t,$samp);
	$samp=$_[0];
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		if($untrim)
		{
			if($t->{PAIRED})
			{

			} else {

			}
		}
		if($trim)
		{
			if($t->{PAIRED})
			{

			} else {

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
			issuecmd("samtools view -uS $projdir/$wdir/$UntrimDir/$SAM/$samp$s$samsuffix | samtools sort /dev/stdin $projdir/$wdir/$UntrimDir/$BAM/$samp$s$sortsuffix");
			issuecmd("samtools index $projdir/$wdir/$UntrimDir/$BAM/$samp$s$bamsuffix");
			issuecmd("samtools idxstats $projdir/$wdir/$UntrimDir/$BAM/$samp$s$bamsuffix > $projdir/$wdir/$UntrimDir/$STATS/$samp$s".".bwa_align_stats.txt");
		}
		if($trim)
		{
			issuecmd("samtools view -uS $projdir/$wdir/$TrimDir/$SAM/$samp$s$trimsuffix$samsuffix | samtools sort /dev/stdin $projdir/$wdir/$TrimDir/$BAM/$samp$s$trimsuffix$sortsuffix");
			issuecmd("samtools index $projdir/$wdir/$TrimDir/$BAM/$samp$s$trimsuffix$bamsuffix");
			issuecmd("samtools idxstats $projdir/$wdir/$TrimDir/$BAM/$samp$s$trimsuffix$bamsuffix > $projdir/$wdir/$TrimDir/$STATS/$samp$s".".trimmed.bwa_align_stats.txt");
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
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$ALN");
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$SAM");
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$BAM");
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$STATS");
	}
	if($trim)
	{
		issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$ALN");
		issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$SAM");
		issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$BAM");
		issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$STATS");
	}
}
