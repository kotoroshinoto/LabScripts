source /UCHC/HPC/Everson_HPC/cluster_scripts/user_profile/modules.sh
export MODULEPATH=/UCHC/HPC/Everson_HPC/cluster_scripts/modulefiles:$MODULEPATH
module load EversonLabBiotools/1.0
#module load hugeseq/1.0
function reloadmod {
module unload EversonLabBiotools/1.0 && module load EversonLabBiotools/1.0
}
function listmake {
	make -qp | awk -F':' '/^[a-zA-Z0-9][^$#\/\t=]*:([^=]|$)/ {split($1,A,/ /);for(i in A)print A[i]}'
}