# script_genecalls.py
# version 2013.06.21

import processor
import os

file_first = 'SKU09988NCBL4A.4GATK.recal.realn.filtered.bam.snps.dcov100.raw.vcf' #CHANGE
file_second = 'SKU09991NFBL4A.4GATK.recal.realn.filtered.bam.snps.dcov100.raw.vcf' #CHANGE
file_output = 'out_genecalls_NCTC_NFTF_' #CHANGE

input_directory = os.path.join(os.path.dirname(__file__), 'Input/')
output_directory = os.path.join(os.path.dirname(__file__), 'Output')
file_directory = ['Pt4']
#file_directory = ['Pt1', 'Pt3A', 'Pt3B', 'Pt4', 'Pt5A', 'Pt5B']
lines_skip = 122

for x in range(0, len(file_directory)):
	processor.processGeneCalls(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)