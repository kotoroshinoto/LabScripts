source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/cluster_scripts/modulefiles/EversonLabBiotools/1.0

HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh
GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fa
BWAINDEX=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fa
BOWTIEINDEX=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE/ucsc.hg19
BOWTIE2INDEX=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE2/ucsc.hg19
DBSNP=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf
GENES=/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf
TRANSCRIPTOME=/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes
MINQUAL=30
MAPQUAL=40
GENOME_TYPE=hg19
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
JAVA_RAM=33G
#250,000*33=8250000
MRECORDS=8250000
TARGET_BED=/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed
CURDIR=`pwd -P`
BWA_RAM=10G
JAVA_JOB_RAM=50G
SHIMMER_RAM=20G
GENERIC_JOB_RAM=30G
rRNA=/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Sequence/AbundantSequences/humRibosomal.fa
ENSEMBL_GENES_GC=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/ENSEMBL_ANNOTATIONS/GC/gencode.v7.gc.txt
ENSEMBL_GENES=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/ENSEMBL_ANNOTATIONS/GTF/gencode.v7.annotation.gtf
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
	echo order "$GROUPLBL"_$1 after "$GROUPLBL"_$2 >> $SJM_FILE
}