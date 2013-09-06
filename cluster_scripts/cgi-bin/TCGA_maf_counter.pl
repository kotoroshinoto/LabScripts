use strict;
use warnings;
use Cwd;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling);
use List::MoreUtils qw(uniq);
use FileHandle;
use Scalar::Util;

#define object types used in this process:
package MAFentry;
our %col2index;
_initializeVars();
sub _initializeVars{
	my @columns;
	my $i;
	push(@columns,'Hugo_Symbol','hEntrez_Gene_Id','Center','Ncbi_Build','Chrom','Start_Position','End_Position','Strand','Variant_Classification','Variant_Type','Reference_Allele','Tumor_Seq_Allele1','Tumor_Seq_Allele2','Dbsnp_Rs','Dbsnp_Val_Status','Tumor_Sample_Barcode','Matched_Norm_Sample_Barcode','Match_Norm_Seq_Allele1','Match_Norm_Seq_Allele2','Tumor_Validation_Allele1','Tumor_Validation_Allele2','Match_Norm_Validation_Allele1','Match_Norm_Validation_Allele2','Verification_Status','Validation_Status','Mutation_Status','Sequencing_Phase','Sequence_Source','Validation_Method','Score','Bam_File','Sequencer','Tumor_Sample_UUID','Matched_Norm_Sample_UUID','File_Name','Archive_Name','Line_Number');
	$i=0;
	foreach my $col(@columns){
		$MAFentry::col2index{$col}=$i;
		$i++;
	}
#	GetIndex('Hugo_Symbol');
}
sub GetIndex{
#	my $class=shift;
	my $colname=shift;
	if(defined($col2index{$colname})){
		my $retval=$col2index{$colname};
#		print "$colname : $retval\n";
		return $retval;
	} else {
#		print "$colname not a defined column\n";
		return undef;
	}
}
sub new{
	my $class = shift;
	my $self = {
		Hugo_Symbol=>"",
		Entrez_Gene_Id=>"",
		Center=>"",
		Ncbi_Build=>"",
		Chrom=>"",
		Start_Position=>"",
		End_Position=>"",
		Strand=>"",
		Variant_Classification=>"",
		Variant_Type=>"",
		Reference_Allele=>"",
		Tumor_Seq_Allele1=>"",
		Tumor_Seq_Allele2=>"",
		Dbsnp_Rs=>"",
		Dbsnp_Val_Status=>"",
		Tumor_Sample_Barcode=>"",
		Matched_Norm_Sample_Barcode=>"",
		Match_Norm_Seq_Allele1=>"",
		Match_Norm_Seq_Allele2=>"",
		Tumor_Validation_Allele1=>"",
		Tumor_Validation_Allele2=>"",
		Match_Norm_Validation_Allele1=>"",
		Match_Norm_Validation_Allele2=>"",
		Verification_Status=>"",
		Validation_Status=>"",
		Mutation_Status=>"",
		Sequencing_Phase=>"",
		Sequence_Source=>"",
		Validation_Method=>"",
		Score=>"",
		Bam_File=>"",
		Sequencer=>"",
		Tumor_Sample_UUID=>"",
		Matched_Norm_Sample_UUID=>"",
		File_Name=>"",
		Archive_Name=>"",
		Line_Number=>""
	};
	return bless $self, $class;
}
sub processline{
	my ($class,@params)= @_;
	if (Scalar::Util::blessed($class)){die "used as an object method";}
	if (scalar(@params) != 1){die "method takes 1 and only 1 argument";}
	my @columns=split('\t',$params[0]);
	if (scalar(@columns) != 37){die "line does not have correct # of columns (37)"}
	my $newobj=$class->new();
	$newobj->{Hugo_Symbol}=$columns[0];
	$newobj->{Entrez_Gene_Id}=$columns[1];
	$newobj->{Center}=$columns[2];
	$newobj->{Ncbi_Build}=$columns[3];
	$newobj->{Chrom}=$columns[4];
	$newobj->{Start_Position}=$columns[5];
	$newobj->{End_Position}=$columns[6];
	$newobj->{Strand}=$columns[7];
	$newobj->{Variant_Classification}=$columns[8];
	$newobj->{Variant_Type}=$columns[9];
	$newobj->{Reference_Allele}=$columns[10];
	$newobj->{Tumor_Seq_Allele1}=$columns[11];
	$newobj->{Tumor_Seq_Allele2}=$columns[12];
	$newobj->{Dbsnp_Rs}=$columns[13];
	$newobj->{Dbsnp_Val_Status}=$columns[14];
	$newobj->{Tumor_Sample_Barcode}=$columns[15];
	$newobj->{Matched_Norm_Sample_Barcode}=$columns[16];
	$newobj->{Match_Norm_Seq_Allele1}=$columns[17];
	$newobj->{Match_Norm_Seq_Allele2}=$columns[18];
	$newobj->{Tumor_Validation_Allele1}=$columns[19];
	$newobj->{Tumor_Validation_Allele2}=$columns[20];
	$newobj->{Match_Norm_Validation_Allele1}=$columns[21];
	$newobj->{Match_Norm_Validation_Allele2}=$columns[22];
	$newobj->{Verification_Status}=$columns[23];
	$newobj->{Validation_Status}=$columns[24];
	$newobj->{Mutation_Status}=$columns[25];
	$newobj->{Sequencing_Phase}=$columns[26];
	$newobj->{Sequence_Source}=$columns[27];
	$newobj->{Validation_Method}=$columns[28];
	$newobj->{Score}=$columns[29];
	$newobj->{Bam_File}=$columns[30];
	$newobj->{Sequencer}=$columns[31];
	$newobj->{Tumor_Sample_UUID}=$columns[32];
	$newobj->{Matched_Norm_Sample_UUID}=$columns[33];
	$newobj->{File_Name}=$columns[34];
	$newobj->{Archive_Name}=$columns[35];
	$newobj->{Line_Number}=$columns[36];
	return $newobj;
	
}
1;
package FeatureCounter;
sub new{
	my $class = shift;
	my $self = {
		counts=>{}
		#TODO provide interaction methods
	};
	return bless $self, $class;
}
sub __appendcount{
	my ($self,@params)= @_;
	if (scalar(@params) != 1){die "method takes 1 and only 1 argument";}
	if(defined($self->{counts}{$params[0]})){
		$self->{counts}{$params[0]}++;
	} else {
		$self->{counts}{$params[0]}=1;
	}
}
sub __countIf{
	my ($self,@params)= @_;
	if (scalar(@params) != 2){die "method takes 2 and only 2 arguments";}
	if($params[1]){
		$self->__appendcount($params[0]);
	}
}
sub toString{
#	print "toString run\n";
	my $self=shift;
	my @keys=sort(keys($self->{counts}));
	my $retval='';
	foreach my $key(@keys){
		$retval.="$key\t$self->{counts}{$key}\n";
	}
	return $retval;
}
1;
package GeneMutCounter;
use parent -norequire, 'FeatureCounter';
sub count{
#	print "Gene  mutationcount run\n";
	my ($self,@params)= @_;
	if (scalar(@params) != 1){die "method takes 1 and only 1 argument";}
	my $maf=$params[0];
#	print (join("\t",@_),"\n");
	#TODO take a MAF entry and append count where appropriate
#	if (defined($self->{counts}{$_[0]})){
#		$self->{counts}{$_[0]}++;
#	} else {
#		$self->{counts}{$_[0]}=1;
#	}
}
1;
package SampMutCounter;
use parent -norequire, 'FeatureCounter';
sub count{
#	print "Sample mutation count run\n";
	my ($self,@params)= @_;
	if (scalar(@params) != 1){die "method takes 1 and only 1 argument";}
	my $maf=$params[0];
#	print (join("\t",@_),"\n");
	#TODO take a MAF entry and append count where appropriate
	
#	if (defined($self->{counts}{$_[1]})){
#		$self->{counts}{$_[1]}++;
#	} else {
#		$self->{counts}{$_[1]}=1;
#	}
}
1;
package MutTypeCounter;
use parent -norequire, 'FeatureCounter';
sub count{
#	print "Mutation type count run\n";
	my ($self,@params)= @_;
	if (scalar(@params) != 1){die "method takes 1 and only 1 argument";}
	my $maf=$params[0];
#	print (join("\t",@_),"\n");
	#TODO take a MAF entry and append count where appropriate
#	$self->{count}++;
#	if (defined($self->{counts}{$_[2]})){
#		$self->{counts}{$_[2]}++;
#	} else {
#		$self->{counts}{$_[2]}=1;
#	}
}
1;

package main;
my $help=0;#indicates usage should be shown and nothing should be done
my ($illuminaFile,$solidFile,$opts);
our ($countGene,$countPatient,$countMutType)= (0) x 3;

$opts = GetOptions ("Illumina|f=s" => \$illuminaFile,	# path to illumina data
						"Solid|F=s"   => \$solidFile,	# path to solid data
						"countGene|G" => \$countGene, #list of steps to assume were already run, assume order as well (acts like pipeline)
						"countPatient|P" => \$countPatient,
						"countMutType|M" => \$countMutType,
						"help|h" =>\$help);
#print "$joinSOLO, $joinSTEPS, $splitCROSS\n";
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
#create count objects and store as references
sub CountMafFile{
	my @counters;
	my $mafFile=$_[0];
	if($countGene){
		push(@counters,GeneMutCounter->new());
	}
	if($countPatient){
		push(@counters,SampMutCounter->new());
	}
	if($countMutType){
		push(@counters,MutTypeCounter->new());
	}
	my $maf=FileHandle->new($mafFile,'r');
	unless(defined($maf)){die "Could not open maf file: $mafFile"};
	#count line-by-line
	my $linecount=0;
	foreach my $line (<$maf>){
		#skip first line (its the header)
		if($linecount){
			my $entry=MAFentry->processline($line);
			#TODO counts/maf entry pre-conditionals here
			if(isCountable($entry)){
				foreach my $counter(@counters){
					$counter->count($entry);
				}
			}
		}
		$linecount++;       
	}
	$maf->close();
}
sub isCountable{
	my $maf=$_[0];
	return 1;
}

my @IlluminaCounters;
if(defined($illuminaFile) and length($illuminaFile) > 0){
	@IlluminaCounters=CountMafFile($illuminaFile);
}

my @SOLiDCounters;
if(defined($solidFile) and length($solidFile) > 0){
	@SOLiDCounters=CountMafFile($solidFile);
}

