#!/bin/bash -x
bwa sampe \
-P $1 \
$2 \
$3 \
$4\
$5| \
samtools view -bS /dev/stdin > $6
