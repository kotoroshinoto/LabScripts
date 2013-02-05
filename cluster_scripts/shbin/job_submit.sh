#!/bin/bash -x

HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh
JOBSCRIPT=$1
shift
JOBNAME=$1
shift
DATE=`date +"%Y-%m-%d-%H-%M-%S"`
#
qsub -l h_vmem=40G -cwd -N $JOBNAME -o ./qsub_logs/$JOBNAME.$DATE.out -e ./qsub_logs/$JOBNAME.$DATE.err $HANDLER_SCRIPT -- $JOBSCRIPT $@
