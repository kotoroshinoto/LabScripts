#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

bwa sampe \
-P $BWAINDEX \
$1_1.fq.aligned \
$1_2.fq.aligned \
$1_1.fq \
$1_2.fq | \
samtools view -bS /dev/stdin > $1.bam
#2>$CURDIR/bwa_logs/$1.bwa.sampe.log | 
#2>$CURDIR/bwa_logs/$1.samtools.view.log

