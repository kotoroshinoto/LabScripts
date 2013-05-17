source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift
SJM_FILE=./Filters.sjm

rm -f $SJM_FILE

function filterRegions {

mkdir -p filters

mkdir -p filters/tmp

SJM_JOB Filter2_SAMtools_$SAMPLE $GENERIC_JOB_RAM "samtools view -bh -f 0x3 -F 0x60C -q $MAPQUAL -o ./filters/$1.samtools_filtered.bam ./filters/$1.bedfiltered.bam"

SJM_JOB Filter3_RMDuplicates_$SAMPLE $JAVA_JOB_RAM "java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/MarkDuplicates.jar \
TMP_DIR=$CURDIR/filters/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./filters/$1.samtools_filtered.bam \
O=./filters/$1.rmduplicates.bam \
M=./filters/$1.dupmetrics \
REMOVE_DUPLICATES=true \
AS=true"

SJM_JOB_AFTER Filter3_RMDuplicates_$SAMPLE Filter2_SAMtools_$SAMPLE

SJM_JOB Filter4_SORT_$SAMPLE $JAVA_JOB_RAM "java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/SortSam.jar \
TMP_DIR=$CURDIR/filters/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./filters/$1.rmduplicates.bam \
O=$2 \
SORT_ORDER=coordinate"
#rm ./filters/$1.*

SJM_JOB_AFTER Filter4_SORT_$SAMPLE Filter3_RMDuplicates_$SAMPLE
}

function getStats {
#1 filename
#2 RAM
#3 curdir
#4 mrecords
#5 genome
	SJM_JOB $2_GetStats_$SAMPLE $JAVA_JOB_RAM "samtools index $1 && \
samtools flagstat $1 >$1.flagstat && \
samtools idxstats $1 >$1.idxstat && \
java -Xmx$JAVA_RAM  -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar ~/HPC/picard/bin/CollectAlignmentSummaryMetrics.jar \
TMP_DIR=$CURDIR \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=$1 \
O=$1.align_sum_metrics.txt \
R=$GENOME"
}

function Filter_per_file {
	mkdir -p sjm_logs
SAMPLE=$1

#Step5:
#	samtools view filter (Map Q 40, remove unmapped, keep mapped in proper pair, keep meeting vendor QC requirement)
#	picard duplicate filter
#	Bedtools intersectBed region filter 
filterRegions $1.4GATK.recal.realn.bam $1.4GATK.recal.realn.filtered.bam

#Step6: (repeat step 3 on filtered files)
getStats $1.4GATK.recal.realn.filtered.bam PostFiltered
SJM_JOB_AFTER PostFiltered_GetStats_$SAMPLE Filter4_SORT_$SAMPLE

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
}

for var in "$@"
do
	#ARGS=$(echo $var | tr "," "\n")
	#echo "ARGS: $ARGS"
    Filter_per_file $ARGS
done