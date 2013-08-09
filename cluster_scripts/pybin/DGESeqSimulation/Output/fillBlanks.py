'''
Created on Aug 9, 2013

@author: mgooch, bing
'''
import sys

files=[]
data=[]
if len(sys.argv) <= 1:
    sys.stderr.write('Error: please input at least two files\n')
print('Generating file databases...')
for item in sys.argv:
    files.append(item)
    data.append(dict())

print('Examining files...')
for x in range(0, len(files)):
    inputfile=open(files[x],"r")
    for line in inputfile:
        splitline=line.split("\t")
        for y in range(0, len(data)):
            if x == y: # data corresponds to file
                transcript=[]
                transcript.append(splitline[0])
                try:
                    transcript.append(splitline[2])
                except: #some lines are not formated with 4 columns
                    continue
                data[x][splitline[0]]=transcript
            else:#data is from another file, add missing entries
                if not splitline[0] in data:
                    transcript=[]
                    transcript.append(splitline[0])
                    transcript.append('0')
                    #TODO add values like zeroes or blanks to appropriate columns
                    data[y][splitline[0]]=transcript
    inputfile.close()

print('Writing results...')
for x in range(0, len(files)):
    outputfilename=files[x]
    outputfile=open("merged_" + outputfilename, "w")
    for geneLabel in data[x].keys().sort():
        outputfile.write("\t".join(data[x][geneLabel]) + "\n")
    outputfile.close()