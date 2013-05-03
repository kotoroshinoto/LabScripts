source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift
SJM_FILE=./InsertSize.sjm
rm $SJM_FILE
function InsertSizePerSample {
	SJM_JOB INS_SIZE_PRE_$1 $JAVA_JOB_RAM "java -jar /UCHC/HPC/Everson_HPC/picard/bin/CollectInsertSizeMetrics.jar I=$1.bam O=$1.pre.insertsize.out H=$1.pre.insertsize.histo R=$GENOME"
	SJM_JOB INS_SIZE_POST_$1 $JAVA_JOB_RAM "java -jar /UCHC/HPC/Everson_HPC/picard/bin/CollectInsertSizeMetrics.jar I=$1.4GATK.recal.realn.filtered.bam O=$1.post.insertsize.out H=$1.post.insertsize.histo R=$GENOME"
}

for var in "$@"
do
	#ARGS=$(echo $var | tr "," "\n")
	#echo "ARGS: $ARGS"
    InsertSizePerSample $var
done