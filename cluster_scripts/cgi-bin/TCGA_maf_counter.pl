use strict;
use warnings;
use Cwd;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling);
use List::MoreUtils qw(uniq);

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
	#TODO finish this
}
1;
package FeatureCounter;
sub new{
	my $class = shift;
	my $self = {
		counts=>{}
		#TODO, change this into a hash, give interaction methods
	};
	return bless $self, $class;
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
	print "Gene  mutationcount run\n";
	my $self=shift;
	print (join("\t",@_),"\n");
	#TODO take a MAF entry and append count where appropriate
	if (defined($self->{counts}{$_[0]})){
		$self->{counts}{$_[0]}++;
	} else {
		$self->{counts}{$_[0]}=1;
	}
}
1;
package SampMutCounter;
use parent -norequire, 'FeatureCounter';
sub count{
	print "Sample mutation count run\n";
	my $self=shift;
	print (join("\t",@_),"\n");
	#TODO take a MAF entry and append count where appropriate
	
	if (defined($self->{counts}{$_[1]})){
		$self->{counts}{$_[1]}++;
	} else {
		$self->{counts}{$_[1]}=1;
	}
}
1;
package MutTypeCounter;
use parent -norequire, 'FeatureCounter';
sub count{
	print "Mutation type count run\n";
	my $self=shift;
	print (join("\t",@_),"\n");
	#TODO take a MAF entry and append count where appropriate
	$self->{count}++;
	if (defined($self->{counts}{$_[2]})){
		$self->{counts}{$_[2]}++;
	} else {
		$self->{counts}{$_[2]}=1;
	}
}
1;

package main;
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
my @Counters;
push(@Counters,GeneMutCounter->new(),SampMutCounter->new(),MutTypeCounter->new());
my @maf;
push (@maf,'gene','samp','type');
foreach my $counter(@Counters){
	$counter->count(@maf);
}
foreach my $counter(@Counters){
	print ($counter->toString());
}
#TODO load files