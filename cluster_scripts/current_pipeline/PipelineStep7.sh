#!/bin/bash -x
source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fasta
DBSNP=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf
MINQUAL=30
MAPQUAL=40
GENOME_TYPE=hg19
NC=$1
NF=$2
TC=$3
TF=$4
GROUPLBL=$5
HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh
SJM_FILE=./Step7.sjm
CURDIR=`pwd`

function SJM_JOB {
	JOBNAME=$1
	shift
	echo "job_begin
	name $GROUPLBL-$JOBNAME
	memory 20G
	module EversonLabBiotools/1.0
	queue all.q
	directory $CURDIR
	cmd $HANDLER_SCRIPT $@
job_end" >> $SJM_FILE
}
function SJM_JOB_AFTER {
	echo "order $1 after $2" >> $SJM_FILE
}  
function runPileupSingle {
	FNAME=$2
	FNAME=${FNAME//./_}
	SJM_JOB MPILEUP_SINGLE_$FNAME "samtools mpileup -DS -q 10 -Q 20 -f $GENOME $1 > $2"
}

function runPileupPair {
	FNAME=$3
	FNAME=${FNAME//./_}
SJM_JOB MPILEUP_PAIR_$FNAME "samtools mpileup -DS -q 10 -Q 20 -f $GENOME $1 $2 > $3"
}

function runVarscan {
	FNAME=$2
	FNAME=${FNAME//./_}
SJM_JOB VARSCAN_$FNAME "java -jar /UCHC/HPC/Everson_HPC/VarScan/bin/VarScan.v2.3.2.jar somatic $1 $2 --mpileup 1"
}

function runShimmer {
	FNAME=$3
	FNAME=${FNAME//./_}
SJM_JOB $FNAME "shimmer.pl --ref $GENOME $1 $2 --outdir $3 --mapqual $MAPQUAL --minqual $MINQUAL --buildver $GENOME_TYPE"
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

SJM_JOB_AFTER $GROUPLBL-VARSCAN_NC_TC_somatic $GROUPLBL-MPILEUP_PAIR_NC_TC_pileup
SJM_JOB_AFTER $GROUPLBL-VARSCAN_NC_TF_somatic $GROUPLBL-MPILEUP_PAIR_NC_TF_pileup
SJM_JOB_AFTER $GROUPLBL-VARSCAN_NF_TF_somatic $GROUPLBL-MPILEUP_PAIR_NF_TF_pileup
SJM_JOB_AFTER $GROUPLBL-VARSCAN_NC_NF_somatic $GROUPLBL-MPILEUP_PAIR_NC_NF_pileup
SJM_JOB_AFTER $GROUPLBL-VARSCAN_TC_TF_somatic $GROUPLBL-MPILEUP_PAIR_TC_TF_pileup

mkdir -p sjm_logs
echo "log_dir $CURDIR/sjm_logs" >> $SJM_FILE