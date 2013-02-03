#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/custom_scripts/bin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

NC=$(echo $1 | tr "," "\n")
NF=$(echo $2 | tr "," "\n")
TC=$(echo $3 | tr "," "\n")
TF=$(echo $4 | tr "," "\n")
GROUPLBL=$5
SJM_FILE=./Step2-6.sjm

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
 
SJM_JOB Prep1_Clean_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/CleanSam.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=$1 \
O=./GATK_prep/$1.cleaned

SJM_JOB Prep2_Reorder_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/ReorderSam.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.cleaned \
O=./GATK_prep/$1.reordered \
R=$GENOME

SJM_JOB Prep3_AddReplReadGroups_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
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

SJM_JOB Prep4_FixMateInfo_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/FixMateInformation.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.addReadGroups \
O=./GATK_prep/$1.fixMateInfo

SJM_JOB Prep5_MarkDuplicates_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/MarkDuplicates.jar \
TMP_DIR=$CURDIR/GATK_prep/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./GATK_prep/$1.fixMateInfo \
O=$2 \
M=$2.dupmetrics \
REMOVE_DUPLICATES=false \
AS=true
#rm ./GATK_prep/$1.*
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
	SJM_MULTILINE_JOB_START $2_GetStats_$1 $JAVA_JOB_RAM
SJM_MULTILINE_JOB_CMD samtools flagstat $1 >$1.flagstat
SJM_MULTILINE_JOB_CMD samtools index  $1
SJM_MULTILINE_JOB_CMD samtools idxstats $1 >$1.idxstat
SJM_MULTILINE_JOB_CMD java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar ~/HPC/picard/bin/CollectAlignmentSummaryMetrics.jar \
TMP_DIR=$CURDIR \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=$1 \
O=$1.align_sum_metrics.txt \
R=$GENOME
SJM_MULTILINE_JOB_END
}

function recalibrateBaseQual {
	SJM_MULTILINE_JOB_START Prep6_Recalibrate_$1 $JAVA_JOB_RAM 
SJM_MULTILINE_JOB_CMD samtools index $1
SJM_MULTILINE_JOB_CMD java -Xmx$JAVA_RAM -Xms$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T BaseRecalibrator \
-I $1 \
-R $GENOME \
-knownSites $DBSNP \
-o $1.grp

SJM_MULTILINE_JOB_CMD java -Xmx$JAVA_RAM -Xms$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T PrintReads \
-I $1 \
-R $GENOME \
-BQSR $1.grp \
-o $2
SJM_MULTILINE_JOB_END
}


function indelrealign {
	SJM_MULTILINE_JOB_START Prep7_Realign_$1 $JAVA_JOB_RAM 
##create target intervals file
SJM_MULTILINE_JOB_CMD java -Xmx$JAVA_RAM -Xms$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
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
SJM_MULTILINE_JOB_CMD java -Xmx$JAVA_RAM -Xms$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/GATK/bin/GenomeAnalysisTK.jar \
-T IndelRealigner \
-R $GENOME \
-I $1 \
-targetIntervals $1.indel.intervals \
-o $2
SJM_MULTILINE_JOB_END
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

SJM_JOB Filter1_BEDtools_$1 $GENERIC_JOB_RAM bedtools intersect \
-u -abam $1 \
-b $TARGET_BED \
>./filters/$1.bedfiltered.bam

SJM_JOB Filter2_SAMtools_$1 $GENERIC_JOB_RAM samtools view -bh -f 0x3 -F 0x60C -q $MAPQUAL ./filters/$1.bedfiltered >./filters/$1.samtools_filtered.bam

mkdir -p filters/tmp

SJM_JOB Filter3_RMDuplicates_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/MarkDuplicates.jar \
TMP_DIR=$CURDIR/filters/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./filters/$1.samtools_filtered.bam \
O=./filters/$1.rmduplicates.bam \
M=./filters/$1.dupmetrics \
REMOVE_DUPLICATES=true \
AS=true

SJM_JOB Filter4_SORT_$1 $JAVA_JOB_RAM java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar /UCHC/HPC/Everson_HPC/picard/bin/SortSam.jar \
TMP_DIR=$CURDIR/filters/tmp \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=./filters/$1.rmduplicates.bam \
O=$2 \
SORT_ORDER=coordinate
#rm ./filters/$1.*
}
function Prepare_N_Filter_per_file {
#Step2: 
#	clean/Reorder/fix/add-replace-read-groups/sort

prepare4GATK $1.bam $1.4GATK.bam $2 $3 $4 $5 $6

#Step3:
#	samtools index
#	Post alignment summary statistics with Picard/samtools flagstat and idxstat
#	Picard GC bias metrics

getStats $1.4GATK.bam PreFiltered

#Step4: 
#	GATK BaseRecalibration and the analyze covariates before and after
#	GATK indelRealignment

recalibrateBaseQual $1.4GATK.bam $1.4GATK.recal.bam
indelrealign $1.4GATK.recal.bam $1.4GATK.recal.realn.bam

#Step5:
#	samtools view filter (Map Q 40, remove unmapped, keep mapped in proper pair, keep meeting vendor QC requirement)
#	picard duplicate filter
#	Bedools intersectBed region filter 

filterRegions $1.4GATK.recal.realn.bam $1.4GATK.recal.realn.filtered.bam

#Step6: (repeat step 3 on filtered files)
getStats $1.4GATK.recal.realn.filtered.bam PostFiltered
}

Prepare_N_Filter_per_file $NC
Prepare_N_Filter_per_file $NF
Prepare_N_Filter_per_file $TC
Prepare_N_Filter_per_file $TF

mkdir -p sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE