#!/bin/bash
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift

NC=$1
NF=$2
TC=$3
TF=$4

SJM_FILE=./CuffDiffMerge.sjm

function runSJMfile {
	mkdir -p sjm_logs
	sjm $SJM_FILE
}

function doCuffMerge {
	SJM_JOB CuffMerge_$1_$2 25G "printf \"%s\n%s\" \"./$1_CUFFLINKS/transcripts.gtf\" \"./$2_CUFFLINKS/transcripts.gtf\" | cuffmerge -g $GENES -s $BWAINDEX -p 8 -o $1_$2_Merge /dev/stdin"
#CuffMerge.sh $1 $2 
}

function doCuffDiff {
	SJM_JOB CuffDiff_$1_$2 25G "cuffdiff -o $1_$2_Diff -b $GENOME -p 8 -L $1,$2 -u ./$1_$2_Merge/merged.gtf ./$1_TOPHAT/accepted_hits.bam ./$2_TOPHAT/accepted_hits.bam"
	SJM_JOB_AFTER CuffDiff_$1_$2 CuffMerge_$1_$2 
}

function doCummerBund {
	echo "DERPBUND"
}

function doCuffDiffMergePerFilePair {
	doCuffMerge $1 $2
	doCuffDiff $1 $2
	doCummerBund $1 $2
}

rm -f $SJM_FILE
touch $SJM_FILE
doCuffDiffMergePerFilePair $NC $NF 
doCuffDiffMergePerFilePair $TC $TF 
doCuffDiffMergePerFilePair $NC $TC
doCuffDiffMergePerFilePair $NF $TF
doCuffDiffMergePerFilePair $NC $TF

mkdir -p $CURDIR/sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
