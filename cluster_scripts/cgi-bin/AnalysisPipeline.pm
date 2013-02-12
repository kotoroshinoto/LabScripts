#!/usr/bin/env perl
package AnalysisPipeline;
1;

package PipelineStep;
use strict;
use warnings;
	#example job from a status file:
	#name PT5_RNA_BWA_SAMPE_TSRNA091711TCBL5
    #memory 10737418240 M
    #queue all.q
    #module EversonLabBiotools/1.0
    #directory /home/CAM/mgooch/Everson/Projects/Bladder/Pt5/RNA
    #status done
    #id 151327
    #cpu_usage 2704
    #wallclock 2596
    #memory_usage 1808490496
    #swap_usage 0
    #cmd /UCHC/HPC/Everson_HPC/custom_scripts/bin/run_qsub.sh bwa_run.sh TSRNA091711TCBL5
sub new {
	my $self = {};
	$self->{name}= undef;
	$self->{memory}= undef;
	$self->{queue}= undef;
	$self->{module}= undef;
	$self->{directory}= undef;
	$self->{status}= undef;#waiting,failed,done
	$self->{cmd}= undef;
	#following not really needed to generate new jobs, but if parsing an SJM file, it will be good to have placeholders
	$self->{id}= undef;
	$self->{cpu_usage}= undef;
	$self->{wallclock}= undef;
	$self->{memory_usage}= undef;
	$self->{swap_usage}= undef;
	bless($self); # but see below
	return $self;
}
1;