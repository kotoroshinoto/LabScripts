#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift
DOWNCOUNT=$1
shift
NC=$1.4GATK.recal.realn.filtered.bam
NF=$2.4GATK.recal.realn.filtered.bam
TC=$3.4GATK.recal.realn.filtered.bam
TF=$4.4GATK.recal.realn.filtered.bam

SJM_FILE=./RunMutectDownsample.sjm
function runMutect {
	LBLN=$3
	LBLT=$4
	FNAME=$3_$4
	SJM_JOB MUTECT__DOWNSAMP_$FNAME $JAVA_JOB_RAM "mutect --downsample_to_coverage $DOWNCOUNT -R $GENOME --cosmic $COSMIC --dbsnp $DBSNP --intervals $TARGET_BED --input_file:normal $1 --input_file:tumor $2 --out mutect_call_stats.downsample.$FNAME.txt --coverage_file mutect_coverage.downsample.$FNAME.wig.txt --vcf mutect.downsample.$FNAME.vcf --tumor_sample_name $LBLT --normal_sample_name $LBLN --enable_extended_output"
}

function runSJMfile {
	mkdir -p sjm_logs
	sjm $SJM_FILE
}

rm $SJM_FILE
touch $SJM_FILE

runMutect $NC $TC NC TC
runMutect $NC $TF NC TF
runMutect $NF $TF NF TF
runMutect $NC $NF NC NF
runMutect $NF $NC NF NC
runMutect $TC $TF TC TF

mkdir -p sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE