#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh
GROUPLBL=$1
#echo "group label: $GROUPLBL" 
shift

SJM_FILE=./RunMutectUnpaired.sjm

#NC=$1.4GATK.recal.realn.filtered.bam
#NF=$2.4GATK.recal.realn.filtered.bam
#TC=$3.4GATK.recal.realn.filtered.bam
#TF=$4.4GATK.recal.realn.filtered.bam

function runMutect {
	SJM_JOB MUTECT_$1 $JAVA_JOB_RAM "mutect -R $GENOME --cosmic $COSMIC --dbsnp $DBSNP --intervals $TARGET_BED --input_file:tumor $2 --out mutect_call_stats.$1.txt --coverage_file mutect_coverage.$1.wig.txt --vcf mutect.$1.vcf --tumor_sample_name $1 --enable_extended_output"
}

function runSJMfile {
	mkdir -p sjm_logs
	sjm $SJM_FILE
}

#rm $SJM_FILE
#touch $SJM_FILE
echo "#!/usr/bin/env sjm" > $SJM_FILE
#runMutect $NC $TC NC TC
#runMutect $NC $TF NC TF
#runMutect $NF $TF NF TF
#runMutect $NC $NF NC NF
#runMutect $NF $NC NF NC
#runMutect $TC $TF TC TF

for var in "$@"
do
	#ARGS=$(echo $var | tr "," " ")
	#echo "ARGS: $ARGS"
    runMutect $var $var.4GATK.recal.realn.filtered.bam
done
mkdir -p sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
