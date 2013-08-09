'''
fill_blanks.py script
version 2013.08.09

@author: mgooch, Bing
fills in transcripts (with a zero value for expression) that are not expressed in specific samples to allow spreadsheet comparisons

'''
import os, sys

input_dir = os.path.join(os.path.dirname(__file__), 'Output')
old_dir = os.getcwd()
os.chdir(input_dir)

files=[]
data=[]
if len(sys.argv) <= 1:
    sys.stderr.write('Error: please input at least two files\n')
print('Generating file databases...')
for x in range(1, len(sys.argv)):
    files.append(sys.argv[x])
    data.append(dict())

print('Examining files...')
for x in range(0, len(files)):
    inputfile=open(files[x],"r")
    for line in inputfile:
        splitline=line.split("\t")
        if len(splitline) == 4:
            for y in range(0, len(data)):
                if x == y: # data corresponds to file
                    transcript=[]
                    transcript.append(splitline[0])
                    transcript.append(splitline[2])
                    data[y][splitline[0]]=transcript
                else: # data is from another file, add missing entries
                    if splitline[0] not in data[y]:
                        transcript=[]
                        transcript.append(splitline[0])
                        transcript.append('0')
                        data[y][splitline[0]]=transcript
    inputfile.close()

print('Writing results...')
for x in range(0, len(files)):
    outputfilename=files[x]
    outputfile=open("merged_" + outputfilename, "w")
    geneLabels=[]
    for item in data[x].keys():
        geneLabels.append(item)
    geneLabels.sort()
    geneLabels.reverse()
    for geneLabel in geneLabels:
        outputfile.write("\t".join(data[x][geneLabel]) + "\n")
    outputfile.close()
    
os.chdir(old_dir)