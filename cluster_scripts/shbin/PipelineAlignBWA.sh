#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

NC=$(echo $1 | tr "," "\n")
NF=$(echo $2 | tr "," "\n")
TC=$(echo $3 | tr "," "\n")
TF=$(echo $4 | tr "," "\n")
GROUPLBL=$5
SJM_FILE=./Step1.sjm

#function runBWA {
#bwa aln -t 10 $BWAINDEX \
#$1. \
#-f $1.aligned \
#&>./logs/$1.bwa.aln.log
#
#bwa aln -t 10 $BWAINDEX \
#$2 \
#-f $2.aligned \
#&>./logs/$2.bwa.aln.log
#
#bwa sampe -P $BWAINDEX \
#$1.aligned \
#$2.aligned \
#$1 \
#$2
#}
function BWA_ALN {
	SJM_JOB BWA_ALN_$1_$2 $BWA_RAM "bwa aln -t 10 $BWAINDEX $1_$2.fq -f $1_$2.fq.aligned"
	SJM_JOB_AFTER BWA_ALN_$1_$2 LINKFILE_$1_$2
}

function BWA_SAMPE {
	SJM_JOB BWA_SAMPE_$1 $BWA_RAM "bwa_run.sh $1"
	SJM_JOB_AFTER BWA_SAMPE_$1 BWA_ALN_$1_1
	SJM_JOB_AFTER BWA_SAMPE_$1 BWA_ALN_$1_2
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

#needs minimal ram, only making a softlink
function linkfiles {
	SJM_JOB LINKFILE_$1_1 1G "ln -fs $2 ./$1_1.fq"
	SJM_JOB LINKFILE_$1_2 1G "ln -fs $3 ./$1_2.fq"
}
#Step1:  (separate step)
#	create softlinks to fastq files in working directory
#	FASTQ to SAM using BWA default setting (If possible generate FASTQC and other FASTQ stats)
#	bwa aln (files 1 & 2)->bwa sampe
#	Change output to bam format (save file space)

function BWA_per_file_pair {
	linkfiles $1 $2 $3
	createSJMfile_BWA $1
	#runSJMfile $1
}

rm $SJM_FILE
touch $SJM_FILE
BWA_per_file_pair $NC
BWA_per_file_pair $NF
BWA_per_file_pair $TC
BWA_per_file_pair $TF

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
