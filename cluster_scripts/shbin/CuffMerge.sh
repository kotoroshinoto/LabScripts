#!/bin/bash
source /UCHC/HPC/Everson_HPC/cluster_scripts/shbin/ScriptSettings.lib.sh
echo "./$1_CUFFLINKS/transcripts.gtf
./$2_CUFFLINKS/transcripts.gtf" | cuffmerge -g $GENES -s $BWAINDEX -p 8 -o $1_$2_Merge /dev/stdin