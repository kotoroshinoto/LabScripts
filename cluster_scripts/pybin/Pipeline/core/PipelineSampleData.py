#!/usr/bin/env python
import sys
import os
class SampleData:
    def __init__(self):
        self.paired=None
        #Set true if paired-end, false is single-end
        self.source1=None
        self.source2=None
        self.orig1=None
        self.orig2=None
        #read group labels use some combo of these as name prefix
        #5 labels
        self.ID=None
        self.LB=None
        self.PL=None
        self.PU=None
        self.SM=None
        #either 7 or 9 columns
    @staticmethod
    def readBatch(filename):
        files={}
        try:
            f=open(filename,"r")
            for line in f:
                sd=None
                line=line.strip()
                if line != '':
                    sd=SampleData()
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
                        sys.stderr.write("[SampleData.readBatch] tried to parse line with wrong # of columns")
                        return None
                    #print (cols)
                    if files.get(sd.ID) is not None:
                        sys.stderr.write("[SampleData.readBatch] entry already exists for ID: \"%s\"" % sd.ID)
                        return None
                    files[sd.ID]=sd
            return files
        except IOError as ioex:
            sys.stderr.write("IOError exception when trying to open %s: %s" % (filename,os.strerror(ioex.errno)))
            return None
        finally:#should not ever get here
            return None