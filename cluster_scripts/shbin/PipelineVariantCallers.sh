#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

NC=$1.4GATK.recal.realn.filtered.bam
NF=$2.4GATK.recal.realn.filtered.bam
TC=$3.4GATK.recal.realn.filtered.bam
TF=$4.4GATK.recal.realn.filtered.bam
GROUPLBL=$5
SJM_FILE=./CallVariants.sjm
function runMutect {
	
}
function runPileupSingle {
	FNAME=$2
	FNAME=${FNAME//./_}
	SJM_JOB MPILEUP_SINGLE_$FNAME $GENERIC_JOB_RAM "samtools mpileup -DS -q 10 -Q 20 -f $GENOME $1 > $2"
}

function runPileupPair {
	FNAME=$3
	FNAME=${FNAME//./_}
SJM_JOB MPILEUP_PAIR_$FNAME $GENERIC_JOB_RAM "samtools mpileup -DS -q 10 -Q 20 -f $GENOME $1 $2 > $3"
}

function runVarscan {
	FNAME=$2
	FNAME=${FNAME//./_}
SJM_JOB VARSCAN_$FNAME $JAVA_JOB_RAM "java -Xms$JAVA_RAM -Xmx$JAVA_RAM -jar /UCHC/HPC/Everson_HPC/VarScan/bin/VarScan.v2.3.2.jar somatic $1 $2 --mpileup 1"
}

function runShimmer {
	FNAME=$3
	FNAME=${FNAME//./_}
SJM_JOB $FNAME $SHIMMER_RAM "shimmer.pl --ref $GENOME $1 $2 --outdir $3 --mapqual $MAPQUAL --minqual $MINQUAL --buildver $GENOME_TYPE"
}

function runSJMfile {
	mkdir -p sjm_logs
	sjm $SJM_FILE
}

rm $SJM_FILE
touch $SJM_FILE

#Step7: (separate file)
#	Shimmer (BQ 30)
runShimmer $NC $TC NC_TC.shimmer
runShimmer $NC $TF NC_TF.shimmer
runShimmer $NF $TF NF_TF.shimmer
runShimmer $NC $NF NC_NF.shimmer
runShimmer $TC $TF TC_TF.shimmer
#	VarScan somatic and then VarScan high confidence or VarScan filtration
#	Mutect?

runPileupSingle $TC TC.pileup
runPileupSingle $TF TF.pileup
runPileupSingle $NC NC.pileup
runPileupSingle $NF NF.pileup
runPileupPair $NC $TC NC_TC.pileup
runPileupPair $NC $TF NC_TF.pileup
runPileupPair $NF $TF NF_TF.pileup
runPileupPair $NC $NF NC_NF.pileup
runPileupPair $TC $TF TC_TF.pileup
runVarscan NC_TC.pileup NC_TC.somatic
runVarscan NC_TF.pileup NC_TF.somatic
runVarscan NF_TF.pileup NF_TF.somatic
runVarscan NC_NF.pileup NC_NF.somatic
runVarscan TC_TF.pileup TC_TF.somatic
#Need to find a way to incorporate 
#tumor purity, 
#strand bias, 
#VarScan copy number, 
#ABSOLUTE Broad, 
#Bioconductor DNACopy, 
#adjusting for read count.
#capseg??? (CopyN)

SJM_JOB_AFTER VARSCAN_NC_TC_somatic MPILEUP_PAIR_NC_TC_pileup
SJM_JOB_AFTER VARSCAN_NC_TF_somatic MPILEUP_PAIR_NC_TF_pileup
SJM_JOB_AFTER VARSCAN_NF_TF_somatic MPILEUP_PAIR_NF_TF_pileup
SJM_JOB_AFTER VARSCAN_NC_NF_somatic MPILEUP_PAIR_NC_NF_pileup
SJM_JOB_AFTER VARSCAN_TC_TF_somatic MPILEUP_PAIR_TC_TF_pileup

mkdir -p sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE