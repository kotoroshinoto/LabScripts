#!/usr/bin/env perl

use SampleData;
use strict;
use warnings;
use Switch;
sub trim($);
sub ltrim($);
sub rtrim($);

#make script args global
our $ARGC = scalar(@ARGV);
our @argv = @ARGV;
main();

sub main {
	my $usage="";
	my $selection = shift @ARGV;
	switch ( trim( $selection ) ) {
		#DNA pipeline
		case "DNA" {
			DNA_Pipeline();
		}
		#RNA pipeline
		case "RNA" {
			RNA_Pipeline();
		}
		#ERROR CASES
		case "" {
			die "no option selected\nUsage$usage";
		}
		else {
			die "unrecognized option selected\n";
		}
	};
}

sub DNA_Pipeline {
	my $usage="";
	print "DNA Pipeline\n";
	my $selection = shift @ARGV;
	switch ( trim( $selection ) ) {
		#Different Steps
		#case "" {}
		#ERROR CASES
		case "" {
			die "no option selected\n";
		}
		else {
			die "unrecognized option selected\n";
		}
	};
}

sub RNA_Pipeline {
	my $usage="";
	print "RNA Pipeline\n";
	my $selection = shift @ARGV;
	switch ( trim( $selection ) ) {
		#Different Steps
		#case "" {}
		#ERROR CASES
		case "" {
			die "no option selected\n";
		}
		else {
			die "unrecognized option selected\n";
		}
	};
}

sub trim($) {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Left trim function to remove leading whitespace
sub ltrim($) {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/^\s+//;
	return $string;
}

# Right trim function to remove trailing whitespace
sub rtrim($) {
	my $string = shift;
	if(!defined($string)){return "";}
	$string =~ s/\s+$//;
	return $string;
}
