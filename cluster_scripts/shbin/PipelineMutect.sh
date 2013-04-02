#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

NC=$1.4GATK.recal.realn.filtered.bam
NF=$2.4GATK.recal.realn.filtered.bam
TC=$3.4GATK.recal.realn.filtered.bam
TF=$4.4GATK.recal.realn.filtered.bam
GROUPLBL=$5
SJM_FILE=./RunMutect.sjm
function runMutect {
	FNAME=$3
	SJM_JOB MUTECT_$FNAME $JAVA_JOB_RAM "mutect -R $GENOME --cosmic $COSMIC --dbsnp $DBSNP --intervals $TARGET_BED --input_file:normal $1 --input_file:tumor $2 --out mutect_call_stats.$FNAME.txt --coverage_file mutect_coverage.$FNAME.wig.txt"
}

function runSJMfile {
	mkdir -p sjm_logs
	sjm $SJM_FILE
}

rm $SJM_FILE
touch $SJM_FILE

runMutect $NC $TC NC_TC
runMutect $NC $TF NC_TF
runMutect $NF $TF NF_TF
runMutect $NC $NF NC_NF
runMutect $TC $TF TC_TF

mkdir -p sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE