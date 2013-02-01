#!/bin/bash -x
source /etc/profile.d/modules.sh
module load /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/1.0
echo "running: \"$@\""
`$@`