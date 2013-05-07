source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift
SJM_FILE=./Filters.sjm
function filterRegions {

mkdir -p filters

mkdir -p filters/tmp

SJM_JOB Filter1_BEDtools_$SAMPLE $GENERIC_JOB_RAM PipelineFilterBedtoolsCMD1.sh $1 $TARGET_BED ./filters/$1.bedfiltered.bam

#SJM_JOB_AFTER Filter1_BEDtools_$SAMPLE Prep7B_Realign_$SAMPLE

SJM_JOB Filter2_SAMtools_$SAMPLE $GENERIC_JOB_RAM samtools view -bh -f 0x3 -F 0x60C -q $MAPQUAL -o ./filters/$1.samtools_filtered.bam ./filters/$1.bedfiltered.bam

SJM_JOB_AFTER Filter2_SAMtools_$SAMPLE Filter1_BEDtools_$SAMPLE

SJM_JOB Filter3_RMDuplicates_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/MarkDuplicates.jar \
TMP_DIR=$CURDIR/filters/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./filters/$1.samtools_filtered.bam \
O=./filters/$1.rmduplicates.bam \
M=./filters/$1.dupmetrics \
REMOVE_DUPLICATES=true \
AS=true

SJM_JOB_AFTER Filter3_RMDuplicates_$SAMPLE Filter2_SAMtools_$SAMPLE

SJM_JOB Filter4_SORT_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/SortSam.jar \
TMP_DIR=$CURDIR/filters/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./filters/$1.rmduplicates.bam \
O=$2 \
SORT_ORDER=coordinate
#rm ./filters/$1.*

SJM_JOB_AFTER Filter4_SORT_$SAMPLE Filter3_RMDuplicates_$SAMPLE
}

function getStats {
#1 filename
#2 RAM
#3 curdir
#4 mrecords
#5 genome
	SJM_JOB $2_GetStats_$SAMPLE $JAVA_JOB_RAM PipelineGetStats.sh $1 $JAVA_RAM $CURDIR $MRECORDS $GENOME
}

function Filter_per_file {
	mkdir -p sjm_logs
SAMPLE=$1
#Step4: 
#	GATK BaseRecalibration and the analyze covariates before and after
#	GATK indelRealignment

recalibrateBaseQual $1.4GATK.bam $1.4GATK.recal.bam
indelrealign $1.4GATK.recal.bam $1.4GATK.recal.realn.bam

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
}

for var in "$@"
do
	#ARGS=$(echo $var | tr "," "\n")
	#echo "ARGS: $ARGS"
    Filter_per_file $ARGS
done