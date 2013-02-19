#!/usr/bin/env perl
package SettingsLib;
#these libs are defined so testing in windows with mobaxterm works.
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';
use Cwd;
use Cwd 'abs_path';
use File::Spec;
our %SettingsList;
#$SettingsList{"PREFIX"}="";
#$SettingsList{"GROUPLBL"}="";
#$SettingsList{"SJM_FILE"}="";
#REST ARE OK FOR NOW
$SettingsList{"HANDLER_SCRIPT"}="/UCHC/HPC/Everson_HPC/cluster_scripts/shbin/run_qsub.sh";
$SettingsList{"GENOME"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/FASTA/ucsc.hg19.fa";
$SettingsList{"BWAINDEX"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BWA/ucsc.hg19.fa";
$SettingsList{"BOWTIEINDEX"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE/ucsc.hg19";
$SettingsList{"BOWTIE2INDEX"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/BOWTIE2/ucsc.hg19";
$SettingsList{"DBSNP"}="/UCHC/HPC/Everson_HPC/reference_data/gatk_bundle/hg19/VCF/dbsnp_137.hg19.vcf";
$SettingsList{"GENES"}="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes/genes.gtf";
$SettingsList{"TRANSCRIPTOME"}="/UCHC/HPC/Everson_HPC/reference_data/igenomes/Homo_sapiens/UCSC/hg19/Annotation/Genes";
$SettingsList{"MODULEFILE"}="EversonLabBiotools/1.0";
$SettingsList{"JOBQUEUE"}="all.q";
$SettingsList{"MINQUAL"}=30;
$SettingsList{"MAPQUAL"}=40;
$SettingsList{"GENOME_TYPE"}="hg19";
#MEMORY SETTINGS
#CURRENT JOB Memory: 40GiB -> 40960MiB
$SettingsList{"JAVA_RAM"}="33G";
#roughly 250,000 per GB
$SettingsList{"MRECORDS"}=250,000*33;
$SettingsList{"TARGET_BED"}="/UCHC/HPC/Everson_HPC/reference_data/agilent_kits/SSKinome/S0292632_Covered.bed";
$SettingsList{"CURDIR"}=abs_path(File::Spec->curdir());
$SettingsList{"BWA_RAM"}="10G";
$SettingsList{"JAVA_JOB_RAM"}="50G";
$SettingsList{"SHIMMER_RAM"}="20G";
$SettingsList{"GENERIC_JOB_RAM"}="30G";

1;