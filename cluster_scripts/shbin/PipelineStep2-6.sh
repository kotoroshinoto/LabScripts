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

#function toBam {
#java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
#-jar /UCHC/HPC/Everson_HPC/picard/bin/SamFormatConverter.jar \
#TMP_DIR=$CURDIR \
#MAX_RECORDS_IN_RAM=$MRECORDS \
#I=$1 \
#O=$2
#}

function getStats {
	#1 filename
#2 RAM
#3 curdir
#4 mrecords
#5 genome
	SJM_JOB $2_GetStats_$SAMPLE $JAVA_JOB_RAM PipelineGetStats.sh $1 $JAVA_RAM $CURDIR $MRECORDS $GENOME
}

function recalibrateBaseQual {
	SJM_JOB Prep6A_Recalibrate_$SAMPLE $JAVA_JOB_RAM samtools index $1
	SJM_JOB Prep6B_Recalibrate_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM \
-jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T BaseRecalibrator \
-I $1 \
-R $GENOME \
-knownSites $DBSNP \
-o $1.grp

	SJM_JOB Prep6C_Recalibrate_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM \
	-jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T PrintReads \
-I $1 \
-R $GENOME \
-BQSR $1.grp \
-o $2

SJM_JOB_AFTER Prep6A_Recalibrate_$SAMPLE Prep5_MarkDuplicates_$SAMPLE
SJM_JOB_AFTER Prep6B_Recalibrate_$SAMPLE Prep6A_Recalibrate_$SAMPLE
SJM_JOB_AFTER Prep6C_Recalibrate_$SAMPLE Prep6B_Recalibrate_$SAMPLE
}


function indelrealign {
	##create target intervals file
	SJM_JOB Prep7A_Realign_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T RealignerTargetCreator \
-R $GENOME \
-I $1 \
-o $1.indel.intervals \
-L $TARGET_BED
#Optional
#-known 	List[RodBinding[VariantContext]] 	[] 	Input VCF file with known indels
#-maxIntervalSize 	int 	500 	maximum interval size; any intervals larger than this value will be dropped
#-minReadsAtLocus 	int 	4 	minimum reads at a locus to enable using the entropy calculation
#-mismatchFraction 	double 	0.0 	fraction of base qualities needing to mismatch for a position to have high entropy
#-windowSize 	int 	10 	window size for calculating entropy or SNP clusters

##use target intervals file & realign
SJM_JOB Prep7B_Realign_$SAMPLE $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T IndelRealigner \
-R $GENOME \
-I $1 \
-targetIntervals $1.indel.intervals \
-o $2

SJM_JOB_AFTER Prep7A_Realign_$SAMPLE Prep6C_Recalibrate_$SAMPLE
SJM_JOB_AFTER Prep7B_Realign_$SAMPLE Prep7A_Realign_$SAMPLE

#Optional
#-consensusDeterminationModel 	ConsensusDeterminationModel 	USE_READS 	Determines how to compute the possible alternate consenses
#-knownAlleles 	List[RodBinding[VariantContext]] 	[] 	Input VCF file(s) with known indels
#-LODThresholdForCleaning 	double 	5.0 	LOD threshold above which the cleaner will clean
#-nWayOut 	String 	NA 	Generate one output file for each input (-I) bam file
#-out 	StingSAMFileWriter 	NA 	Output bam
#Advanced
#-entropyThreshold 	double 	0.15 	percentage of mismatches at a locus to be considered having high entropy
#-maxConsensuses 	int 	30 	max alternate consensuses to try (necessary to improve performance in deep coverage)
#-maxIsizeForMovement 	int 	3000 	maximum insert size of read pairs that we attempt to realign
#-maxPositionalMoveAllowed 	int 	200 	maximum positional move in basepairs that a read can be adjusted during realignment
#-maxReadsForConsensuses 	int 	120 	max reads used for finding the alternate consensuses (necessary to improve performance in deep coverage)
#-maxReadsForRealignment 	int 	20000 	max reads allowed at an interval for realignment
#-maxReadsInMemory 	int 	150000 	max reads allowed to be kept in memory at a time by the SAMFileWriter
#-noOriginalAlignmentTags 	boolean 	false 	Don't output the original cigar or alignment start tags for each realigned read in the output bam
}


function filterRegions {

mkdir -p filters

mkdir -p filters/tmp

SJM_JOB Filter1_BEDtools_$SAMPLE $GENERIC_JOB_RAM PipelineFilter1.sh $1 $TARGET_BED ./filters/$1.bedfiltered.bam

SJM_JOB_AFTER Filter1_BEDtools_$SAMPLE Prep7B_Realign_$SAMPLE

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

function Prepare_N_Filter_per_file {
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
SJM_FILE=./Step2-6.$1.sjm
rm -f $SJM_FILE
touch $SJM_FILE

prepare4GATK $1.bam $1.4GATK.bam $2 $3 $4 $5 $6

#Step3:
#	samtools index
#	Post alignment summary statistics with Picard/samtools flagstat and idxstat
#	Picard GC bias metrics

getStats $1.4GATK.bam PreFiltered
SJM_JOB_AFTER PreFiltered_GetStats_$SAMPLE Prep5_MarkDuplicates_$SAMPLE

#Step4: 
#	GATK BaseRecalibration and the analyze covariates before and after
#	GATK indelRealignment

recalibrateBaseQual $1.4GATK.bam $1.4GATK.recal.bam
indelrealign $1.4GATK.recal.bam $1.4GATK.recal.realn.bam

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

#echo $NC
#echo $NF
#echo $TC
#echo $TF
for var in "$@"
do
	ARGS=$(echo $1 | tr "," "\n")
	#echo "ARGS: $ARGS"
    Prepare_N_Filter_per_file $ARGS
done