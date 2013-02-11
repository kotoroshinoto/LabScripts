#!/usr/bin/env perl
package SampleData;
use strict;
sub new {
	my $self = {};
	#Set true if paired-end, false is single-end
	$self->{PAIRED} = undef;
	#
	$self->{SOURCE1} = undef;
	$self->{ORIG1} = undef;

	$self->{SOURCE2} = undef;
	$self->{ORIG2} = undef;
	bless($self); # but see below
	return $self;
 }

sub readbatch{
	#should implement slightly different format for paired end files
	my (@lines);
	my ($line);
	my (@splt);
	my ($batchfile);
	$batchfile=$_[0];
	my (%files);
	if (!defined($batchfile)){die "no batch file given to SampleData::readbatch!\n";}
	open (FILE, "<",$batchfile) or die $!;
	@lines=<FILE>;
	chomp @lines;
	close (FILE);
	if(@lines < 1){ die "Empty Batch File!";}
	foreach(@lines){
		if(length($_) != 0){
			#print "\n".'"'.$_.'"'."\n";
			@splt=split("\t",$_);
			if( @splt != 5 && @splt != 3 ){ 
				print "Error on item: $_\n";
				die  "bad batch format! wrong number columns (".scalar(@splt).")";
			}
			
			if(@splt == 5){#paired end entry
				#source1 (tab) file1 (tab) source2 (tab) file2 (tab) label
				if(defined($files{$splt[4]})){die "entry already exists for ".$files{$splt[4]}."!";}
				$files{$splt[4]}=SampleData->new();
				$files{$splt[4]}->{PAIRED}=1;

				$files{$splt[4]}->{SOURCE1}=$splt[0];
				$files{$splt[4]}->{ORIG1}=$splt[1];

				$files{$splt[4]}->{SOURCE2}=$splt[2];
				$files{$splt[4]}->{ORIG2}=$splt[3];
				#print("PAIRED! \n");
			} else {#single-end entry
				#source (tab) file (tab) label
				if(defined($files{$splt[2]})){die "entry already exists for ".$files{$splt[2]}."!";}
				$files{$splt[2]}= SampleData->new();
				$files{$splt[2]}->{PAIRED}=0;

				$files{$splt[2]}->{SOURCE1}=$splt[0];
				$files{$splt[2]}->{ORIG1}=$splt[1];
				#print("NOT PAIRED! \n");
			}
		}
	}
	return \%files;
}

1;
