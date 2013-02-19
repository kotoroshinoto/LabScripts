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
opendir(DIR, "$jarpath");
my @FILES=readdir(DIR);
closedir(DIR);
my @names=stripjarnames(@FILES);
print "\n@FILES\n";
print "\n@names\n";
my $jar=File::Spec->catfile($jarpath,$jarfile);
my $command="java -Xmx$java_heap_ram -Xms$java_heap_ram -jar $jar @ARGV";
print "$command\n";
system ($command);

sub stripjarnames{
	my @injars=@_;
	my @outnames;
	for my $jar (@injars){
		my $ext=rindex($jar,".jar");
		push @outnames,substr($jar,0,length($jar)-$ext);
	}
	return @outnames;
}