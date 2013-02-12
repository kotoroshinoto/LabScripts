perl PipelineTemplateGenerator.pl --input='FQ,$FQ1,$PREFIX_1.fq' --input='FQ,$FQ2,$PREFIX_2.fq' \
--output='BAM,$BAM,$PREFIX.bam' --template=test \
--subjob='name=$GROUPLBL_$PREFIX_BWA_ALN_1,memory=$BWA_RAM,cmd=bwa aln -t 10 $BWAINDEX $FQ1 -f $FQ1.aligned' \
--subjob='name=$GROUPLBL_$PREFIX_BWA_ALN_2,memory=$BWA_RAM,cmd=bwa aln -t 10 $BWAINDEX $FQ2 -f $FQ2.aligned' \
--subjob='name=$GROUPLBL_$PREFIX_BWA_SAMPE,memory=$BWA_RAM,cmd=/UCHC/HPC/Everson_HPC/custom_scripts/bin/bwa_run.sh $PREFIX,order_after=$GROUPLBL_$PREFIX_BWA_ALN_1:$GROUPLBL_$PREFIX_BWA_ALN_2'