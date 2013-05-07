#!/bin/bash 
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift
#Clean options
#I=File                        Input file (bam or sam).  Required.
#O=File                        Output file (bam or sam).  Required.

#Reorder Options
#I=File                        Input file (bam or sam).  Required. 
#O=File                        Output file (bam or sam).  Required. 
#R=File                        Reference sequence to reorder reads to match.  A sequence dictionary corresponding to the reference fasta is required.  Create one with CreateSequenceDictionary.jar.  Required.

#readgroups options:
#I=File                        Input file (bam or sam).  Required.
#O=File                        Output file (bam or sam).  Required.
#SO=SortOrder                  Optional sort order to output in. If not supplied OUTPUT is in the same order as INPUT.
#Default value: null. Possible values: {unsorted, queryname, coordinate}
#ID=String                     Read Group ID  Default value: 1. This option can be set to 'null' to clear the default value.
#LB=String                     Read Group Library  Required.
#PL=String                     Read Group platform (e.g. illumina, solid)  Required.
#PU=String                     Read Group platform unit (eg. run barcode)  Required.
#SM=String                     Read Group sample name  Required.
#CN=String                     Read Group sequencing center name  Default value: null.
#DS=String                     Read Group description  Default value: null.
#DT=Iso8601Date                Read Group run date  Default value: null.

#function toBam {
#java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
#-jar /UCHC/HPC/Everson_HPC/picard/bin/SamFormatConverter.jar \
#TMP_DIR=$CURDIR \
#MAX_RECORDS_IN_RAM=$MRECORDS \
#I=$1 \
#O=$2
#}
function prepare4GATK {
mkdir -p GATK_prep
mkdir -p $CURDIR/GATK_prep/tmp
	#echo prepare4GATK
	#echo $1
	#echo $2
	#echo $3
	#echo $4
	#echo $5
	#echo $6
	#echo $7
SJM_JOB Prep1_Clean_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/CleanSam.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=$1 \
O=./GATK_prep/$1.cleaned


SJM_JOB Prep2_Reorder_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/ReorderSam.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.cleaned \
O=./GATK_prep/$1.reordered \
R=$GENOME

SJM_JOB_AFTER Prep2_Reorder_$SAMPLE Prep1_Clean_$SAMPLE

SJM_JOB Prep3_AddReplReadGroups_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/AddOrReplaceReadGroups.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.reordered \
O=./GATK_prep/$1.addReadGroups \
ID=$3 \
LB=$4 \
PL=$5 \
PU=$6 \
SM=$7 \
SO=coordinate

SJM_JOB_AFTER Prep3_AddReplReadGroups_$SAMPLE Prep2_Reorder_$SAMPLE

SJM_JOB Prep4_FixMateInfo_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/FixMateInformation.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.addReadGroups \
O=./GATK_prep/$1.fixMateInfo

SJM_JOB_AFTER Prep4_FixMateInfo_$SAMPLE Prep3_AddReplReadGroups_$SAMPLE

SJM_JOB Prep5_MarkDuplicates_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/MarkDuplicates.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.fixMateInfo \
O=$2 \
M=$2.dupmetrics \
REMOVE_DUPLICATES=false \
AS=true
#rm ./GATK_prep/$1.*
SJM_JOB_AFTER Prep5_MarkDuplicates_$SAMPLE Prep4_FixMateInfo_$SAMPLE
}

function getStats {
#1 filename
#2 RAM
#3 curdir
#4 mrecords
#5 genome
	SJM_JOB $2_GetStats_$SAMPLE $JAVA_JOB_RAM PipelineGetStats.sh $1 $JAVA_RAM $CURDIR $MRECORDS $GENOME
}

function Prepare_per_file {
	mkdir -p sjm_logs
SAMPLE=$1
	#echo Prepare_N_Filter_per_file
	#echo $1
	#echo $2
	#echo $3
	#echo $4
	#echo $5
	#echo $6
#Step2: 
#	clean/Reorder/fix/add-replace-read-groups/sort
SJM_FILE=./GATKprep.$1.sjm
rm -f $SJM_FILE
touch $SJM_FILE

prepare4GATK $1.bam $1.4GATK.bam $2 $3 $4 $5 $6

#Step3:
#	samtools index
#	Post alignment summary statistics with Picard/samtools flagstat and idxstat
#	Picard GC bias metrics

getStats $1.4GATK.bam PreFiltered
SJM_JOB_AFTER PreFiltered_GetStats_$SAMPLE Prep5_MarkDuplicates_$SAMPLE

echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE
}

for var in "$@"
do
	ARGS=$(echo $var | tr "," "\n")
	echo "ARGS: $ARGS"
    Prepare_per_file $ARGS
done