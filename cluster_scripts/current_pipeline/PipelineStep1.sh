#!/bin/bash -x
source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fasta
DBSNP=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf
MINQUAL=30
MAPQUAL=40
GENOME_TYPE=hg19
NC=$(echo $1 | tr "," "\n")
NF=$(echo $2 | tr "," "\n")
TC=$(echo $3 | tr "," "\n")
TF=$(echo $4 | tr "," "\n")
GROUPLBL=$5
HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh
SJM_FILE=./Step1.sjm
CURDIR=`pwd`

function SJM_JOB {
	JOBNAME=$1
	shift
	echo "job_begin
	name "$GROUPLBL"_$JOBNAME
	memory 10G
	module EversonLabBiotools/1.0
	queue all.q
	directory $CURDIR
	cmd $HANDLER_SCRIPT $@
job_end" >> $SJM_FILE
}

function SJM_JOB_AFTER {
	echo "order $1 after $2" >> $SJM_FILE
}

#function runBWA {
#bwa aln -t 10 $GENOME \
#$1. \
#-f $1.aligned \
#&>./logs/$1.bwa.aln.log
#
#bwa aln -t 10 $GENOME \
#$2 \
#-f $2.aligned \
#&>./logs/$2.bwa.aln.log
#
#bwa sampe -P $GENOME \
#$1.aligned \
#$2.aligned \
#$1 \
#$2
#}
function BWA_ALN {
	SJM_JOB BWA_ALN_$1_$2 "bwa aln -t 10 $GENOME $1_$2.fq -f $1_$2.fq.aligned"
	SJM_JOB_AFTER "$GROUPLBL"_BWA_ALN_$1_$2 "$GROUPLBL"_LINKFILE_$1_$2
}

function BWA_SAMPE {
	SJM_JOB BWA_SAMPE_$1 "bwa sampe -P $GENOME $1_1.fq.aligned $1_2.fq.aligned $1_1.fq $1_2.fq | samtools view -bS /dev/stdin > $1.bam"
	SJM_JOB_AFTER "$GROUPLBL"_BWA_SAMPE_$1 "$GROUPLBL"_BWA_ALN_$1_1
	SJM_JOB_AFTER "$GROUPLBL"_BWA_SAMPE_$1 "$GROUPLBL"_BWA_ALN_$1_2
}

function createSJMfile_BWA {
BWA_ALN $1 1
BWA_ALN $1 2
BWA_SAMPE $1
}

function runSJMfile {
	mkdir -p sjm_logs
	sjm $SJM_FILE
}

function linkfiles {
	SJM_JOB LINKFILE_$1_1 "ln -fs $2 ./$1_1.fq"
	SJM_JOB LINKFILE_$1_2 "ln -fs $3 ./$1_2.fq"
}
#Step1:  (separate step)
#	create softlinks to fastq files in working directory
#	FASTQ to SAM using BWA default setting (If possible generate FASTQC and other FASTQ stats)
#	bwa aln (files 1 & 2)->bwa sampe
#	Change output to bam format (save file space)

function BWA_per_file_pair {
	linkfiles $1 $2 $3
	createSJMfile_BWA $1
	#runSJMfile_BWA $1
}

rm $SJM_FILE
touch $SJM_FILE
BWA_per_file_pair $NC
BWA_per_file_pair $NF
BWA_per_file_pair $TC
BWA_per_file_pair $TF

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
