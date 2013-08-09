'''
Created on Aug 9, 2013

@author: mgooch
'''
import sys,os

files=[]
data=[]
for item in sys.argv:
    files.append(item)
    data.append(dict())

for x in range(0, len(files)):
    inputfile=open(files[x],"r")
    for line in inputfile:
        splitline=line.split("\t")
        for y in range(0, len(data)):
            if x == y: # data corresponds to file
                data[x][splitline[0]]=splitline
            else:#data is from another file, add missings entries
                if not data.has_key(splitline[0]):
                    data[y][splitline[0]]=[]
                    data[y][splitline[0]].append(splitline[0])
                    #TODO add values like zeroes or blanks to appropriate columns
    inputfile.close()

for item in data:
    for geneLabel in item.keys().sorted():
        outputfile=open("outputfile","w")
        
        outputfile.close()