#!/bin/bash -x
source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

GENOME=/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fasta

mkdir bwa_logs

CURDIR=`pwd`
echo "current dir: $CURDIR"
bwa aln \
-t 10 \
$GENOME \
$1_$2.fq \
-f $1_$2.fq.aligned \
&>$CURDIR/bwa_logs/$1.bwa.aln.$2.log
