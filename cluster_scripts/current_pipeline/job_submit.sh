#!/bin/bash -x

HANDLER_SCRIPT=/UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh
JOBSCRIPT=$1
shift
JOBNAME=$1
shift

#
qsub -l h_vmem=40G -cwd -N $JOBNAME -o ./qsub_logs/$JOBNAME.step2-6.out -e ./qsub_logs/$JOBNAME.step2-6.err $HANDLER_SCRIPT -- $JOBSCRIPT $@
