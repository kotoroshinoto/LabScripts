#!/usr/bin/env python
import os
SettingsList={}
#SettingsList["PREFIX"]="";
#SettingsList["GROUPLBL"]="";
#SettingsList["SJM_FILE"]="";
#REST ARE OK FOR NOW
SettingsList["HANDLER_SCRIPT"]="/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh";
SettingsList["GENOME"]="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fa";
SettingsList["BWAINDEX"]="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fa";
SettingsList["BOWTIEINDEX"]="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE/ucsc.hg19";
SettingsList["BOWTIE2INDEX"]="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE2/ucsc.hg19";
SettingsList["DBSNP"]="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf";
SettingsList["GENES"]="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf";
SettingsList["TRANSCRIPTOME"]="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes";
SettingsList["MODULEFILE"]="EversonLabBiotools/1.0";
SettingsList["JOBQUEUE"]="all.q";
SettingsList["MINQUAL"]=30;
SettingsList["MAPQUAL"]=40;
SettingsList["GENOME_TYPE"]="hg19";
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
SettingsList["JAVA_RAM"]="33G";
#roughly 250,000 per GB
SettingsList["MRECORDS"]=250000*33;
SettingsList["TARGET_BED"]="/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed";
SettingsList["CURDIR"]=os.path.realpath(os.getcwd())
SettingsList["BWA_RAM"]="10G";
SettingsList["JAVA_JOB_RAM"]="50G";
SettingsList["SHIMMER_RAM"]="20G";
SettingsList["GENERIC_JOB_RAM"]="30G";
#printDict(SettingsList)
import sys
def AssertPaths():
    if sys.platform == "cygwin":
        winpybin='/drives/c/Apps/workspace/cluster_scripts/pybin'
        winpymods='/drives/c/Apps/workspace/cluster_scripts/pymodules'
        if winpybin not in sys.path:
            sys.path.append(winpybin)
        if winpymods not in sys.path:
            sys.path.append(winpymods)
    if sys.platform == "win32":
        winpybin='c:\Apps\workspace\cluster_scripts\pybin'
        winpymods='c:\Apps\workspace\cluster_scripts\pymodules'
        if winpybin not in sys.path:
            sys.path.append(winpybin)
        if winpymods not in sys.path:
            sys.path.append(winpymods)
    if sys.platform == "linux":
        linpybin='/UCHC/HPC/Everson_HPC/cluster_scripts/pybin'
        linpymods='/UCHC/HPC/Everson_HPC/cluster_scripts/pymodules'
        if winpybin not in sys.path:
            sys.path.append(linpybin)
        if winpymods not in sys.path:
            sys.path.append(linpymods)