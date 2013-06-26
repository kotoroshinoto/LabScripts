# script_nucleotides.py
# version 2013.06.21

import processor
import os

file_first = 'mutect_call_stats.NC_TC.txt' #CHANGE
file_second = 'mutect_call_stats.NF_TF.txt' #CHANGE
file_output = 'out_nucleo_NCTC_NFTF_' #CHANGE

input_directory = os.path.join(os.path.dirname(__file__), 'Input/')
output_directory = os.path.join(os.path.dirname(__file__), 'Output')
file_directory = ['Pt1', 'Pt3A', 'Pt3B', 'Pt4', 'Pt5A', 'Pt5B']
lines_skip = 0

for x in range(0, len(file_directory)):
	processor.processNucleotides(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)