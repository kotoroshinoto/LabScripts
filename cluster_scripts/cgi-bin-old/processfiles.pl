#!/usr/bin/env perl
use Cwd;
use strict;
use Getopt::Long;
use SampleData;
use Storable;
#switches
our($dl,$extract,$conv2std,$fastqc,$exec,$trim,$help,$cpus,$solqa);
$dl=1;
$extract=1;
$fastqc=1;
$conv2std=1;
$exec=1;
$help=0;
$trim=1;
$solqa=1;

GetOptions( "dl!"=>\$dl,
            "extract!"=>\$extract,
            "fastqc!"=> \$fastqc,
	    "exec!"=>\$exec,
	    "trim!"=>\$trim,
	    "solqa!"=>\$solqa,
	    "help"=>\$help,
	    "cpus=i"=>\$cpus);
if(!defined($cpus)){
#print "CPUS not defined\n";
$cpus=2;
}#else{print "CPUS:$cpus\n";}
our($projdir,$batchfile,%files,$LSort,$SolQA,$TrimDir,$UntrimDir,$FQC,$FQ);

$FQ="FASTQ";
$TrimDir="Trimmed";
$UntrimDir="Untrimmed";
$LSort="LengthSort";
$SolQA="SolexaQA";
$FQC="FASTQC";

our($dldir,$wdir);
#stages suffix
our($donesuffix,$trimsuffix,$filtersuffix);
$filtersuffix=".filtered";
$trimsuffix= ".trimmed";
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

our ($informat,$outformat);
$informat="fastq-sanger";
#alternative: fastq-illumina
$outformat="fastq-sanger";

if($help){#print usage
	my ($usage);
	$usage=$0." <batch_file> [file_formats]\n";
	$usage.="<batch_file> defaults to \"./files.txt\"\n";
	$usage.="[file_formats] defaults to fastq-sanger\n";
	$usage.="usual formats: fastq-sanger or fastq-illumina\n";
	$usage.="Options\n";
	$usage.="--nodl:       | Skip downloading files\n";
	$usage.="--noextract:  | Skip extracting / renaming files\n";
	$usage.="--nofastqc:   | Skip FASTQC analysis of STD fastq files\n";
	$usage.="--notrim:     | Skip Trimming Files based on quality\n";
	$usage.="--nosolqa:    | Skip Solexa QA analysis\n";
	$usage.="--noexec:     | Print commands but don't execute them\n";
	$usage.="--help:       | Display this help information\n";
	print $usage;
	exit(0);
}
#get current directory
$projdir= getcwd();
$dldir='dload';
$wdir='workdir';

#print $projdir."\n";

#Read Batch File
if(@ARGV == 0){
	$batchfile="files.txt";
} elsif(@ARGV == 1){
	$batchfile=$ARGV[0];
} elsif(@ARGV == 2){
	$batchfile=$ARGV[0];
	$informat=$ARGV[1];#TODO change format of batch file to include a tab column for this, so each sequence has its own format associated with it.
}else{
	die "Wrong Number of Arguments to script\n";
}

print "\n";
%files=%{ Storable::dclone(SampleData::readbatch($batchfile)) };
our(@keys);
@keys=sort(keys(%files) );
#print "Incoming format: ".$informat."\n";
#print "Output format: ".$outformat."\n";
mkdirs();
if($arrayid<0)
{
	print "Running in Single Machine Mode\n";
	foreach(@keys)
	{
	#get files from source location on web
	$dl ? dlfiles($_) : print "Skipping File Download Step\n";
	#unzip files and rename output / convert score format to sanger if necessary
	$extract ? extractfiles($_) : print "Skipping Extract & Rename Step\n";
	#trim reads
	$trim ? trimfiles($_) : print "Skipping Quality Trimming Step\n";
	#run fastqc on files pre & post trimming
	$fastqc ? dofastqc($_) : print "Skipping Pre Processing FASTQC Analysis Step\n";
	$solqa ? doSolexaQA($_) : print "Skipping SolexaQA\n";
	}
} else {
	print "Running in Cluster Job Array Mode\n";
	print "ArrayID: $arrayid\n";
	if(!defined($keys[$arrayid])){die "Array ID does not map to a Sample ID!\n";}
	my($samplekey);
	$samplekey=$keys[$arrayid];
	print "Sample: $samplekey\n";
	#get files from source location on web
	$dl ? dlfiles($samplekey) : print "Skipping File Download Step\n";
	#unzip files and rename output / convert score format to sanger if necessary
	$extract ? extractfiles($samplekey) : print "Skipping Extract & Rename Step\n";
	#trim reads
	$trim ? trimfiles($samplekey) : print "Skipping Quality Trimming Step\n";
	#run fastqc on files pre & post trimming
	$fastqc ? dofastqc($samplekey) : print "Skipping Pre Processing FASTQC Analysis Step\n";
	#run SolexaQA on files
	$solqa ? doSolexaQA($samplekey) : print "Skipping SolexaQA\n";
}
exit (0);

sub dlfiles
{
	my($t,$samp);
	$samp=$_[0];
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		if($t->{SOURCE1} ne ""){
			if(isweb($t->{SOURCE1})){
				issuecmd("wget --quiet -P $projdir/$dldir $t->{SOURCE1}/$t->{ORIG1}");
			} else {
				issuecmd("cp $t->{SOURCE1}/$t->{ORIG1} $projdir/$dldir");
			}
		}
		if($t->{PAIRED} && $t->{SOURCE2} ne ""){
			if(isweb($files{$samp}->{SOURCE2})){
				issuecmd("wget --quiet -P $projdir/$dldir $t->{SOURCE2}/$t->{ORIG2}");
			} else {
				issuecmd("cp $t->{SOURCE2}/$t->{ORIG2} $projdir/$dldir");
			}
		}
	}
}

#Eventually would like to extend the below function to issue a return value that can be used in a switch
#to deal with ftp and other source types, currently only recognizes http prefix for web and treats all other 
#sources as local filesystem.
sub isweb
{
	my $s=$_[0];
	if(substr($s,0,4) eq 'http'){return 1;}else{return 0;}
}

sub trimfiles
{
	my($t,$samp);
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	$samp=$_[0];
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		chdir("$wdir");
		if($t->{PAIRED})
		{
			issuecmd("DynamicTrim.pl -d $projdir/$wdir/$TrimDir/$FQ $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2");
			issuecmd("LengthSort.pl -d $projdir/$wdir/$TrimDir/$LSort $projdir/$wdir/$TrimDir/$FQ/$samp$suffix.trimmed $projdir/$wdir/$TrimDir/$FQ/$samp$suffix2.trimmed");
			issuecmd("mv $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.single $projdir/$wdir/$TrimDir/$LSort/$samp$suffix3.trimmed.single");#rename *.single
			issuecmd("mv $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.discard $projdir/$wdir/$TrimDir/$LSort/$samp$suffix3.trimmed.discard");#rename *.discard
			issuecmd("mv $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.paired1 $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.filtered");#rename *.paired1
			issuecmd("mv $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.paired2 $projdir/$wdir/$TrimDir/$LSort/$samp$suffix2.trimmed.filtered");#rename *.paired2
		}else{
			issuecmd("DynamicTrim.pl -d $projdir/$wdir/$TrimDir/$FQ $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix");
			issuecmd("LengthSort.pl -d $projdir/$wdir/$TrimDir/$LSort $projdir/$wdir/$TrimDir/$FQ/$samp$suffix");
			issuecmd("mv $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.single $projdir/$wdir/$TrimDir/$LSort/$samp$suffix.trimmed.filtered");#rename *.single
			#issuecmd("mv ");#rename *.discard
		}
		chdir("..");
	}
}

#should probably add handling of different types of zips in the future (ex: tar.gz, *.zip, *.rar)
sub extractfiles
{
	my($t,$samp);
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	$samp=$_[0];
	print "Extracting $samp File!\n";
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		issuecmd("gunzip -c $projdir/$dldir/$t->{ORIG1} | seqret ".$informat."::/dev/stdin ".$outformat."::$projdir/$wdir/$UntrimDir/$FQ/$samp$suffix");
		$t->{PAIRED} ? issuecmd("gunzip -c $projdir/$dldir/$t->{ORIG2} | seqret ".$informat."::/dev/stdin ".$outformat."::$projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2") : 1;
	}
}

sub doSolexaQA
{	
	my($t,$samp);
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	$samp=$_[0];
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$SolQA/$samp"."_QA $projdir/$wdir/$TrimDir/$SolQA/$samp"."_trimmed_QA");
		if($t->{PAIRED}){
		issuecmd("rm $projdir/$wdir/$UntrimDir/$SolQA/$samp"."_QA/$samp$suffix".".*");
;		issuecmd("rm $projdir/$wdir/$UntrimDir/$SolQA/$samp"."_QA/$samp$suffix2".".*");
		issuecmd("rm $projdir/$wdir/$TrimDir/$SolQA/$samp"."_trimmed_QA/$samp$suffix".".*");
		issuecmd("rm $projdir/$wdir/$TrimDir/$SolQA/$samp"."_trimmed_QA/$samp$suffix2".".*");
		issuecmd("SolexaQA.pl -d $projdir/$wdir/$UntrimDir/$SolQA/$samp"."_QA $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2");
		issuecmd("SolexaQA.pl -d $projdir/$wdir/$TrimDir/$SolQA/$samp"."_trimmed_QA $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix$filtersuffix $projdir/$wdir/$TrimDir/$LSort/$samp$suffix2$trimsuffix$filtersuffix");
		} else {
		issuecmd("rm $projdir/$wdir/$UntrimDir/$SolQA/$samp"."_QA/$samp$suffix".".*");
		issuecmd("rm $projdir/$wdir/$TrimDir/$SolQA/$samp"."_trimmed_QA/$samp$suffix".".*");
		issuecmd("SolexaQA.pl -d $projdir/$wdir/$UntrimDir/$SolQA/$samp"."_QA $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix");
		issuecmd("SolexaQA.pl -d $projdir/$wdir/$TrimDir/$SolQA/$samp"."_trimmed_QA $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix$filtersuffix");
		}
	}
}

sub dofastqc
{
	my($t,$samp);
	if(scalar(@_) != 1 ){die "Wrong # of Arguments to subroutine";}
	$samp=$_[0];
	if(defined($files{$samp}))
	{
		$t=$files{$samp};
		issuecmd("/UCHC/Everson/tools/FastQC/fastqc -o $projdir/$wdir/$UntrimDir/$FQC --noextract $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix");
		issuecmd("/UCHC/Everson/tools/FastQC/fastqc -o $projdir/$wdir/$TrimDir/$FQC --noextract $projdir/$wdir/$TrimDir/$LSort/$samp$suffix$trimsuffix$filtersuffix");
		if($t->{PAIRED}){
		issuecmd("/UCHC/Everson/tools/FastQC/fastqc -o $projdir/$wdir/$UntrimDir/$FQC --noextract $projdir/$wdir/$UntrimDir/$FQ/$samp$suffix2");
		issuecmd("/UCHC/Everson/tools/FastQC/fastqc -o $projdir/$wdir/$TrimDir/$FQC --noextract $projdir/$wdir/$TrimDir/$LSort/$samp$suffix2$trimsuffix$filtersuffix");
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
	issuecmd("mkdir -p $projdir/$dldir");
	issuecmd("mkdir -p $projdir/$wdir");
	issuecmd("mkdir -p $projdir/$wdir/$UntrimDir");
	issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$FQ");
	issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$FQC");
	issuecmd("mkdir -p $projdir/$wdir/$UntrimDir/$SolQA");
	issuecmd("mkdir -p $projdir/$wdir/$TrimDir");
	issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$FQ");
	issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$FQC");
	issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$SolQA");
	issuecmd("mkdir -p $projdir/$wdir/$TrimDir/$LSort");
}
