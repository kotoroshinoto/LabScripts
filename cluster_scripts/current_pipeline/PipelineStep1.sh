#!/bin/bash -x
source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fasta
DBSNP=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf
MINQUAL=30
MAPQUAL=40
GENOME_TYPE=hg19

function runBWA {
bwa aln -t 10 $GENOME \
$1. \
-f $1.aligned \
&>./logs/$1.bwa.aln.log

bwa aln -t 10 $GENOME \
$2 \
-f $2.aligned \
&>./logs/$2.bwa.aln.log

bwa sampe -P $GENOME \
$1.aligned \
$2.aligned \
$1 \
$2
}

function createSJMfile_BWA {
CURDIR=`pwd`
echo "job_begin
	name $1_bwa_align_1
	#module EversonLabBiotools/1.0
	#parallel_env mpi
	#slots 10
	memory 10G
	queue all.q
	directory $CURDIR
	cmd /UCHC/HPC/Everson_HPC/custom_scripts/bin/bwa_aln.sh $1 1
job_end" > $1.job.sjm
echo "job_begin
	name $1_bwa_align_2
	#module EversonLabBiotools/1.0
	#parallel_env mpi
	#slots 10
	memory 10G
	queue all.q
	directory $CURDIR
	cmd /UCHC/HPC/Everson_HPC/custom_scripts/bin/bwa_aln.sh $1 2
job_end" >> $1.job.sjm
echo "job_begin
	name $1_bwa_sampe
	#module EversonLabBiotools/1.0
	memory 10G
	queue all.q
	directory $CURDIR
	cmd /UCHC/HPC/Everson_HPC/custom_scripts/bin/bwa_run.sh $1
job_end" >> $1.job.sjm
echo "order $1_bwa_sampe after $1_bwa_align_1
order $1_bwa_sampe after $1_bwa_align_2" >> $1.job.sjm
echo "log_dir $CURDIR/sjm_logs" >> $1.job.sjm
}

function runSJMfile_BWA {
	mkdir sjm_logs
	sjm $1.job.sjm
}

function linkfiles {
	ln -s $2 ./$1_1.fq
	ln -s $3 ./$1_2.fq
}
#Step1:  (separate step)
#	create softlinks to fastq files in working directory
#	FASTQ to SAM using BWA default setting (If possible generate FASTQC and other FASTQ stats)
#	bwa aln (files 1 & 2)->bwa sampe
#	Change output to bam format (save file space)


linkfiles $1 $2 $3
createSJMfile_BWA $1
runSJMfile_BWA $1
