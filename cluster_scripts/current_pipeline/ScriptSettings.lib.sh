source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh
GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fasta
BWAINDEX=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fasta
DBSNP=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf
MINQUAL=30
MAPQUAL=40
GENOME_TYPE=hg19
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
JAVA_RAM=33G
#250,000*33=8250000
MRECORDS=8250000
TARGET_BED=/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed
CURDIR=`pwd`
BWA_RAM=10G
JAVA_JOB_RAM=50G
SHIMMER_RAM=20G
GENERIC_JOB_RAM=30G
function SJM_MULTILINE_JOB_START {
	JOBNAME=$1
	shift
	JOBRAM=$1
	shift
	echo "job_begin
	name "$GROUPLBL"_$JOBNAME
	memory $JOBRAM
	module EversonLabBiotools/1.0
	queue all.q
	directory $CURDIR
	cmd_begin" >> $SJM_FILE
}
function SJM_MULTILINE_JOB_CMD {
	echo "$@" >> $SJM_FILE
}
function SJM_MULTILINE_JOB_END {
	echo "cmd_end
job_end" >> $SJM_FILE
}
function SJM_JOB {
	JOBNAME=$1
	shift
	JOBRAM=$1
	shift
	echo "job_begin
	name "$GROUPLBL"_$JOBNAME
	memory $JOBRAM
	module EversonLabBiotools/1.0
	queue all.q
	directory $CURDIR
	cmd $HANDLER_SCRIPT $@
job_end" >> $SJM_FILE
}
function SJM_JOB_AFTER {
	echo "order $1 after $2" >> $SJM_FILE
}