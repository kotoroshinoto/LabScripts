'''
reader.py script
Version 2013.07.13

@author: Bing

'''
import os
 
input_directory = os.path.join(os.path.dirname(__file__), 'Input/')
 
old_dir = os.getcwd()
os.chdir(os.path.dirname(__file__))
f = open(filename,"r")
            for line in f:
				line = line.split("\t")
				line
 
 
 def readGTF(filename):
        #files = {}
        try:
            f = open(filename,"r")
            for line in f:
				line = line.split("\t")
				line
				
                data = None
                line=line.strip()
                if line != '':
                    data = SampleData()
                    cols=line.split("\t")
                    if len(cols) == 7:
                        #print ("entry is single")
                        sd.paired=False
                        sd.source1=cols[0]
                        sd.orig1=cols[1]
                        sd.ID=cols[2]
                        sd.LB=cols[3]
                        sd.PL=cols[4]
                        sd.PU=cols[5]
                        sd.SM=cols[6]
                    elif len(cols) == 9:
                        #print ("entry is paired")
                        sd.paired=True
                        sd.source1=cols[0]
                        sd.orig1=cols[1]
                        sd.source2=cols[2]
                        sd.orig2=cols[3]
                        sd.ID=cols[4]
                        sd.LB=cols[5]
                        sd.PL=cols[6]
                        sd.PU=cols[7]
                        sd.SM=cols[8]
                    else:
                        raise PipelineError("[SampleData.readBatch] tried to parse line with wrong # of columns\n")
                        return None
                    #print (cols)
                    if files.get(sd.ID) is not None:
                        raise PipelineError("[SampleData.readBatch] entry already exists for ID: \"%s\"\n" % sd.ID)
                        return None
                    files[sd.ID]=sd
            return files
        except IOError as ioex:
            raise PipelineError("[SampleData.readBatch]IOError exception when trying to open %s: %s\n" % (filename,os.strerror(ioex.errno)))