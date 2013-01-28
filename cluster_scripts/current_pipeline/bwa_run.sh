#!/bin/bash -x
source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fasta
CURDIR=`pwd`

bwa sampe \
-P $GENOME \
$1_1.fq.aligned \
$1_2.fq.aligned \
$1_1.fq \
$1_2.fq 2>$CURDIR/bwa_logs/$1.bwa.sampe.log | \
samtools view -bS /dev/stdin > $1.bam 2>$CURDIR/bwa_logs/$1.samtools.view.log

