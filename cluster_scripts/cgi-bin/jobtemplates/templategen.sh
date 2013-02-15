perl PipelineTemplateGenerator.pl \
--suffix='.bwa' --template=BWA_ALIGN_PAIRED \
-V '$FQ1=$PREFIX$CUMSUFFIX_1.fq' \
-V '$FQ2=$PREFIX$CUMSUFFIX_2.fq' \
-V '$BAM=$ADJPREFIX$SUFFIX.bam' \
--subjob='name=$GROUPLBL_$PREFIX_BWA_ALN_1,memory=$BWA_RAM,cmd=bwa aln -t 10 $BWAINDEX $FQ1 -f $FQ1.aligned' \
--subjob='name=$GROUPLBL_$PREFIX_BWA_ALN_2,memory=$BWA_RAM,cmd=bwa aln -t 10 $BWAINDEX $FQ2 -f $FQ2.aligned' \
--subjob='name=$GROUPLBL_$PREFIX_BWA_SAMPE,memory=$BWA_RAM,cmd=/UCHC/HPC/Everson_HPC/custom_scripts/bin/bwa_sampe.sh $BWAINDEX $FQ1.aligned $FQ2.aligned $FQ1 $FQ2 $BAM,order_after=$GROUPLBL_$PREFIX_BWA_ALN_1:$GROUPLBL_$PREFIX_BWA_ALN_2'