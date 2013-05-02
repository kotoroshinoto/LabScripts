source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift

function InsertSizePerSample {
	
}

for var in "$@"
do
	ARGS=$(echo $var | tr "," "\n")
	echo "ARGS: $ARGS"
    InsertSizePerSample $ARGS
done