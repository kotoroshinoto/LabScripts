#!/usr/bin/env perl
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';
use strict;
use warnings;
use BiotoolsSettings;
my $java_heap_ram=${SettingsLib::SettingsList}{"JAVA_RAM"};
my $jarpath="/UCHC/HPC/Everson_HPC/picard/bin";
my $jarfile="";
my $jar=File::Spec->catfile($jarpath,$jarfile);
my $command="java -Xmx$java_heap_ram -Xms$java_heap_ram -jar $jar @ARGV";
print "$command\n";
system ($command);