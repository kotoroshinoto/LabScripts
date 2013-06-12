source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift

function Genotype_per_file {
	
}

for var in "$@"
do
	#ARGS=$(echo $var | tr "," "\n")
	#echo "ARGS: $ARGS"
    Genotype_per_file $var
done