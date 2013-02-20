#!/usr/bin/env perl

use strict;
use warnings;
use FileHandle;
my $infile=shift @ARGV;
my $outfile=shift @ARGV;
my ($infh,$outfh);

if(!defined($infile)){
	$infh = FileHandle->new("<&STDIN") or die $!."\n";
} else {
	$infh= FileHandle->new("< $infile") or die $!."\n";
}
if(!defined($outfile)){
	$outfh = FileHandle->new("<&STDOUT") or die $!."\n";
}else {
	$outfh = FileHandle->new("< $outfile") or die $!."\n";
}
my @lines=<$infh>;
chomp(@lines);
my @tabsplit;
my @outlines;
for my $line (@lines){
 	print "$line\n";
 	if(!( ($line =~ m/^#.+$/) || ($line =~ m/^\s*$/) )){
 		@tabsplit=split ("\t",$line);
 		if(scalar(@tabsplit) != 8){die "NOT A VCF, not 8 columns!\n"};
 		if(!($tabsplit[0] =~ m/^chr.+/)){
 			$tabsplit[0]='chr'.$tabsplit[0];
 		}
 		push @outlines, join("\t",@tabsplit);
 	} else {
 		push @outlines, $line;
 	}
}

for my $line (@outlines){
	print $outfh $line."\n";
}