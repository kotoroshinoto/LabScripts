#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

NC=$(echo $1 | tr "," "\n")
NF=$(echo $2 | tr "," "\n")
TC=$(echo $3 | tr "," "\n")
TF=$(echo $4 | tr "," "\n")
GROUPLBL=$5
SJM_FILE=./TopCuff.sjm

function doTophat {
	SJM_JOB TOPHAT_$1 100G "tophat -p 8 --GTF $GENES --transcriptome-index $TRANSCRIPTOME -o $2 $BOWTIE2INDEX $1_1.fq $1_2.fq"
	SJM_JOB_AFTER TOPHAT_$1 LINKFILE_$1_1
	SJM_JOB_AFTER TOPHAT_$1 LINKFILE_$1_2
}

function doCufflinks {
	SJM_JOB CUFFLINKS_$1 100G "cufflinks -p 8 -o $2 -g $GENES -b $GENOME -u $1"
	SJM_JOB_AFTER CUFFLINKS_$1 TOPHAT_$1
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

function doTopCuffPerFilePair {
	linkfiles $1 $2 $3
	doTophat $1 $1_TOPHAT
	doCufflinks $1 $1_CUFFLINKS
	#runSJMfile $1
}

rm $SJM_FILE
touch $SJM_FILE
doTopCuffPerFilePair $NC
doTopCuffPerFilePair $NF
doTopCuffPerFilePair $TC
doTopCuffPerFilePair $TF

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
