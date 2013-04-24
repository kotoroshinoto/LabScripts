#!/bin/bash -x
echo "about to source from modules.sh"
source /etc/profile.d/modules.sh
echo "source complete"
echo "about to load EversonLabBiotools/1.0 module"
module load /UCHC/HPC/Everson_HPC/cluster_scripts/modulefiles/EversonLabBiotools/1.0
echo "module loaded"
#echo "running: \"$@\""
$@
