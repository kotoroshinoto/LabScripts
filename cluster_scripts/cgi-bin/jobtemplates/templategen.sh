#!/bin/bash
perl PipelineTemplateGenerator.pl \
--input='FQ,$FQ1,$(PREFIX)_1.fq' --input='FQ,$FQ2,$(PREFIX)_2.fq' --output='BAM,$BAM,$(PREFIX).bam' --template=test \
--subjob='name=$(GROUPLBL)_$(PREFIX)_BWA_ALN_1,memory=$BWA_RAM,cmd=bwa aln -t 10 $BWAINDEX $FQ1 -f $FQ1.aligned' \
--subjob='name=$(GROUPLBL)_$(PREFIX)_BWA_ALN_2,memory=$BWA_RAM,cmd=bwa aln -t 10 $BWAINDEX $FQ2 -f $FQ2.aligned' \
--subjob='name=$(GROUPLBL)_$(PREFIX)_BWA_SAMPE,memory=$BWA_RAM,cmd=/UCHC/HPC/Everson_HPC/custom_scripts/bin/bwa_run.sh $PREFIX'
