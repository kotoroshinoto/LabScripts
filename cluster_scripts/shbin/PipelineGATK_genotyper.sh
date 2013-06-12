source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
#source ScriptSettings.lib.sh

GROUPLBL=$1
shift

function Genotype_per_file {
	SJM_JOB $2_GATK_GENOTYPE $JAVA_JOB_RAM "GATK \
	-T UnifiedGenotyper \
	-R $GENOME \
	-I $1 \
	--dbsnp $DBSNP \
	-o $1.snps.dcov$3.raw.vcf \
	-stand_call_conf 50.0 \
	-stand_emit_conf 10.0 \
	-dcov $3 \
	-L $TARGET_BED"
	#dcov [50 for 4x, 200 for >30x WGS or Whole exome]
}

for var in "$@"
do
	ARGS=$(echo $var | tr "," "\n")
	#echo "ARGS: $ARGS"
    Genotype_per_file $ARGS
done