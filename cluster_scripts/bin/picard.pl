#!/usr/bin/env perl
if($^O eq 'cygwin'){
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10';
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/5.10/i686-cygwin';
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10';
	use lib 'C:/Apps/workspace/cluster_scripts/lib/perl5/site_perl/5.10/i686-cygwin';
	use lib 'C:/Apps/workspace/cluster_scripts/cgi-bin';
}
use strict;
use warnings;
use BiotoolsSettings;
my $java_heap_ram = ${SettingsLib::SettingsList}{"JAVA_RAM"};
my $jarpath       = "/UCHC/HPC/Everson_HPC/picard/bin";
my $jarfile       = "";
opendir( DIR, "$jarpath" ) or die "Couldn't find picard bin directory: $jarpath \-\-\> ".$!."\n";
my @FILES = readdir(DIR);
closedir(DIR);
my @names = stripjarnames(@FILES);

#print "\n@FILES\n";
#print "\n@names\n";
my $hasMatch = 0;
my $firstArg = shift @ARGV;
if ( defined($firstArg) ) {
	for my $name (@names) {
		if ( $name eq $firstArg ) {
			$hasMatch = 1;
			$jarfile  = $name . ".jar";
			last;
		}
	}
}
if ( !defined($firstArg) || $hasMatch == 0 ) {
	die "Command given does not match existing jar in picard directory!\nAvailable Commands:\n" . join( "\n", @names ) . "\n";
}
my $jar = File::Spec->catfile( $jarpath, $jarfile );
my $command = "java -Xmx$java_heap_ram -Xms$java_heap_ram -jar $jar @ARGV";
print "$command\n";
system($command);

sub stripjarnames {
	my @injars = @_;
	my @outnames;
	for my $jar (@injars) {
		my $ext = rindex( $jar, ".jar" );

		#print "$jar : $ext : ".(length($jar)-$ext)."\n";
		#skip the two library jars, because they aren't executable
		#picard-##.##.jar && sam-##.##.jar
		if ( !( $jar =~ m/^(picard-|sam-)([0-9]+).([0-9]+)(.jar)$/ || $jar =~ m/^\s*.+\s*$/ || $jar =~ m/^\s+$/ || $jar eq "" ) ) {
			push @outnames, substr( $jar, 0, $ext );
		}
	}
	return @outnames;
}
