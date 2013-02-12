#!/usr/bin/env perl
# Trim both sides to remove leading/trailing whitespace
package PipelineUtil;
use strict;
use warnings;
sub trim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim sub to remove leading whitespace
sub ltrim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	return $string;
}

# Right trim sub to remove trailing whitespace
sub rtrim {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/\s+$//;
	return $string;
}
sub GET_SJM_START {
	my $str="";
	my $JOBNAME=shift;
	my $JOBRAM=shift;
	$str.=q(job_begin)."\n";
	$str.=q(name ${GROUPLBL}_).$JOBNAME."\n";
	$str.=q(memory ).$JOBRAM."\n";
	$str.=q(module EversonLabBiotools/1.0)."\n";
	$str.=q(queue all.q)."\n";
	$str.=q(directory ${CURDIR})."\n";
}
sub SJM_MULTILINE_JOB_START {
	my $str=GET_SJM_START @_;
	$str.=q(cmd_begin)."\n";
	return $str;
}
sub SJM_MULTILINE_JOB_CMD {
	my $str=join(" ",@_);
	return $str."\n";
}
sub SJM_MULTILINE_JOB_END {
	return "cmd_end\n";
}
sub SJM_JOB {
	my $str=GET_SJM_START @_;
	$str.=q(cmd $HANDLER_SCRIPT ).join(" ",@_)."\n";
	$str.=q(job_end)."\n";
	#print "str:\n".$str."\n";
	return $str;
}
sub SJM_JOB_AFTER {
	return  q(order ${GROUPLBL}_).$_[0].q( after ${GROUPLBL}_).$_[1];
}

1;

package AnalysisPipeline;
#TODO fix this and remove the next 2 variables, they're not needed for perl
our $GROUPLBL="";
our $SJM_FILE="";
#REST ARE OK FOR NOW
our $HANDLER_SCRIPT="/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh";
our $GENOME="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fa";
our $BWAINDEX="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fa";
our $BOWTIEINDEX="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE/ucsc.hg19";
our $BOWTIE2INDEX="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE2/ucsc.hg19";
our $DBSNP="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf";
our $GENES="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf";
our $TRANSCRIPTOME="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes";
our $MINQUAL=30;
our $MAPQUAL=40;
our $GENOME_TYPE="hg19";
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
our $JAVA_RAM="33G";
#roughly 250,000 per GB
our $MRECORDS=250,000*33;
our $TARGET_BED="/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed";
our $CURDIR=PipelineUtil::trim(`pwd -P`);
our $BWA_RAM="10G";
our $JAVA_JOB_RAM="50G";
our $SHIMMER_RAM="20G";
our $GENERIC_JOB_RAM="30G";

sub new {
	my $class = shift;
	my $self = {};
	$self->{name}=undef;#pipeline name
	$self->{jobs}={};#hash of subjobs: jobname=>object format
	$self->{log_dir}=undef;
	bless $self,$class;
	return $self;
}
sub getOutputPrefix {
	my $self=shift;
	my $inputfile=shift;
}
sub test {
	my $t;
	$GROUPLBL="PT0";
	$t=PipelineUtil::SJM_JOB('BWA_ALN_FILE_1', $BWA_RAM, q(bwa aln -t 10 $BWAINDEX FILE_1.fq -f FILE_1.fq.aligned));
	#print $t."\n";
	my $job=q(print STDERR ").$t.q(";);
	print $job,"\n";
	$job =~ s/\n/\\n/g;
	print $job,"\n";
	if(!defined(eval $job)){
		print $@,"\n";
	} else {
		#print $t,"\n";
	}
	#my $derp=q(print STDERR $BWA_RAM,"\n";);
	#eval $derp;
}
sub parselines {
	
}
1;

package PipelineStep;
use strict;
use warnings;
	#example job from a status file:
	#name PT5_RNA_BWA_SAMPE_TSRNA091711TCBL5
    #memory 10737418240 M
    #queue all.q
    #module EversonLabBiotools/1.0
    #directory /home/CAM/mgooch/Everson/Projects/Bladder/Pt5/RNA
    #status done
    #id 151327
    #cpu_usage 2704
    #wallclock 2596
    #memory_usage 1808490496
    #swap_usage 0
    #cmd /UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh bwa_run.sh TSRNA091711TCBL5
sub new {
	my $class = shift;
	my $self = {};
	$self->{name}= undef;
	$self->{memory}= undef;
	$self->{queue}= undef;
	$self->{module}= undef;
	$self->{directory}= undef;
	$self->{status}= undef;#waiting,failed,done
	$self->{cmd}= ();#list of commands if only 1 member will output in single command mode
	#following not really needed to generate new jobs, but if parsing an SJM file, it will be good to have placeholders
	$self->{id}= undef;
	$self->{cpu_usage}= undef;
	$self->{wallclock}= undef;
	$self->{memory_usage}= undef;
	$self->{swap_usage}= undef;
	$self->{dependencies}=();#list of jobnames that this job must wait for
	$self->{inputs}={};#list of files this step uses (only need to include files produced by previous steps)
	$self->{outputs}={};#list of files this step creates (only need to include files that will be used by other steps)
	
	bless($self, $class); # but see below
	return $self;
}

sub parsejob {
	my $self = shift;
	my $stringarr= shift;
	my $string;
	$string=$$stringarr[0];
	$string=trim($string);
	if($string ne "job_begin"){
		return undef;#cannot parse from here
	}
	while (@{$stringarr}){
		$string=trim(shift (@{$stringarr} ) );
		$string=q($string=").$string.q(");
		eval $string;
		print $string;
	}
}
1;