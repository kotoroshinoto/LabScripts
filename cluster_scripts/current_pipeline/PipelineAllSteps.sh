#!/bin/bash

source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0

PipelineStep1.sh $1 $2 $3 
PipelineStep2-6.sh $1 $4 $5 $6 $7 $8
PipelineStep7.sh $1
