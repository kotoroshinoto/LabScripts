#!/bin/bash
#1 filename
#2 RAM
#3 curdir
#4 mrecords
#5 genome
"samtools index $1 && \
samtools flagstat $1 >$1.flagstat && \
samtools idxstats $1 >$1.idxstat && \
java -Xmx$2 -Xms$2 -Djava.io.tmpdir=$3/GATK_prep/tmp \
-jar ~/HPC/picard/bin/CollectAlignmentSummaryMetrics.jar \
TMP_DIR=$3 \
MAX_RECORDS_IN_RAM=$4 \
I=$1 \
O=$1.align_sum_metrics.txt \
R=$5"