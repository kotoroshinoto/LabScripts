'''
reader.py
version 2013.06.21

reads the directions.txt and tells the processor.py how to treat the file
new: added relative input/outupt folder paths

'''
import processor
import os

input_directory = os.path.join(os.path.dirname(__file__), 'Input/')
output_directory = os.path.join(os.path.dirname(__file__), 'Output')

old_dir = os.getcwd()
os.chdir(os.path.dirname(__file__))

f = open('directions.txt', 'r')

f.readline()

f.readline()
f.readline()
compare_type = f.readline().rstrip()

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

processor.processFile(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)

if compare_type == 'Mutation':
	for x in range(0, len(file_directory)):
		processor.processMutations(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)
elif compare_type == 'Nucleotide':
	for x in range(0, len(file_directory)):
		processor.processNucleotides(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)
elif compare_type == 'Gene Call':
	for x in range(0, len(file_directory)):
		processor.processGeneCalls(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory, lines_skip)
else:
	print('Unknown type of comparison')
	
f.close()