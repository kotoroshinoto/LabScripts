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
	echo "./$1_CUFFLINKS/transcripts.gtf
./$2_CUFFLINKS/transcripts.gtf | cuffmerge -g $GENES -s $BWAINDEX -p 8 -o $1_$2_Merge /dev/stdin"
}

function doCuffDiff {
	echo "DERPDIFF"
}

function doCummerBund {
	echo "DERPBUND"
}

function doCuffDiffMergePerFilePair {
	doCuffMerge $1 $2
	doCuffDiff $1 $2
	doCummerBund $1 $2
}

rm $SJM_FILE
touch $SJM_FILE
doCuffDiffMergePerFilePair $NC $NF 
doCuffDiffMergePerFilePair $TC $TF 
doCuffDiffMergePerFilePair $NC $TC
doCuffDiffMergePerFilePair $NF $TF
doCuffDiffMergePerFilePair $NC $TF

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
