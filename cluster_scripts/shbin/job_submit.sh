#!/bin/bash -x

HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh
JOBNAME=$1
shift
JOBSCRIPT=$1
shift
DATE=`date +"%Y-%m-%d-%H-%M-%S"`
#
qsub -l h_vmem=50G -cwd -N $JOBNAME -o ./qsub_logs/$JOBNAME.$DATE.out -e ./qsub_logs/$JOBNAME.$DATE.err $HANDLER_SCRIPT -- $JOBSCRIPT $@
