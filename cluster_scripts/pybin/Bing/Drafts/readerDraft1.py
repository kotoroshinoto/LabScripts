#reader.py
#version 2013.06.21
'''New: do not need to put folder paths'''

import processor
import os

old_dir = os.getcwd()
os.chdir(os.path.dirname(__file__))

f = open('directions.txt', 'r')

f.readline()
f.readline()
f.readline()
file_first = f.readline().rstrip()

f.readline()
f.readline()
file_second = f.readline().rstrip()

f.readline()
f.readline()
file_output = f.readline().rstrip()

f.readline()
f.readline()
table = f.readline().rstrip()
table = [s.strip().split(', ') for s in table.splitlines()]
file_directory = table[0] ## should make cleaner

string = f.readline()
string = f.readline()
string = f.readline()
lines_skip = int(string)

'''
file_first = 'mutect_call_stats.NC_TC.txt'
file_second = 'mutect_call_stats.NF_TF.txt'
file_output = 'output_NCTC_NFTF_'
file_directory = ['Pt1', 'Pt3A', 'Pt3B', 'Pt4', 'Pt5A', 'Pt5B']
lines_skip = 0
'''
input_directory = os.path.join(os.path.dirname(__file__), 'Input/')
output_directory = os.path.join(os.path.dirname(__file__), 'Output')

for x in range(0, len(file_directory)):
	processor.processMutations(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)
	
f.close()