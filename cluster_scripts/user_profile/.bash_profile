export MODULEPATH=/UCHC/HPC/Everson_HPC/cluster_scripts/modulefiles:$MODULEPATH
module load EversonLabBiotools/1.0
#module load hugeseq/1.0
function reloadmod {
module unload EversonLabBiotools/1.0 && module load EversonLabBiotools/1.0
}