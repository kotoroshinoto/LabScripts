#script.py
#version 2013.06.10
 
'''
Options
	#Type in cmd.exe
	C:\\Python27\python C:\\Users\Bing\Videos\script.py
 	
	#Use in linux
	/home/bing/Documents
 	
	#Use in windows
	C:\\Users\Bing\Videos
 	
'''
import processor
 
file_first = 'mutect_call_stats.NC_TC.txt'
file_second = 'mutect_call_stats.NF_TF.txt'
#'mutect_call_stats.downsample.NC_TC.txt'
 
file_output = 'output_NCTC_NCTF_'
output_directory = 'C:\\\\Users\\Bing\\Videos\\'
input_directory = 'C:\\\\Users\\Bing\\Videos\\Data\\'
file_directory = ['Pt1', 'Pt3A', 'Pt3B', 'Pt4', 'Pt5A', 'Pt5B']
 
for x in range(0, len(file_directory)):
	processor.processFiles(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory)
'''
try:
	for x in range(0, len(file_directory)):
		processor.processTable(file_first, file_second, input_directory + file_directory[x], file_output + file_directory[x] + '.xls', output_directory)
except Exception:
	print 'Error Reading File'
'''