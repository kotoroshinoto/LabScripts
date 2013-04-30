source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift

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

function Prepare_N_Filter_per_file {
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
	ARGS=$(echo $var | tr "," "\n")
	echo "ARGS: $ARGS"
    Prepare_N_Filter_per_file $ARGS
done