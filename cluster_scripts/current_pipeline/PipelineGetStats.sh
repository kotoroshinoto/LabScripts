#!/bin/bash

samtools index  $1
samtools flagstat $1 >$1.flagstat
samtools idxstats $1 >$1.idxstat
java -Xmx$JAVA_RAM -Xms$JAVA_RAM -Djava.io.tmpdir=$CURDIR/GATK_prep/tmp \
-jar ~/HPC/picard/bin/CollectAlignmentSummaryMetrics.jar \
TMP_DIR=$CURDIR \
MAX_RECORDS_IN_RAM=$MRECORDS \
I=$1 \
O=$1.align_sum_metrics.txt \
R=$GENOME