#!/bin/bash -x
source /UCHC/HPC/Everson_HPC/custom_scripts/bin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh
echo "current dir: $CURDIR"
bwa aln \
-t 10 \
$BWAINDEX \
$1_$2.fq \
-f $1_$2.fq.aligned \
&>$CURDIR/bwa_logs/$1.bwa.aln.$2.log
