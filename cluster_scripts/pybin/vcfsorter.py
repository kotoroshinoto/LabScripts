#!/usr/bin/env python
'''
Created on Apr 1, 2013

@author: mgooch
'''
######################################################
# port of vcfsorter.pl to python
#
# Copyright (C) 2011 German Gaston Leparc
#
# sorts VCF by reference genome
#
# usage:
#
# vcfsorter.pl genome.dict myvcf.file > mynewvcf.file
#
######################################################
#from https://code.google.com/p/vcfsorter
import sys,re
import BiotoolsSettings
import DPyGetOpt
import exceptions
#http://ipython.org/ipython-doc/rel-0.10.2/html/api/generated/IPython.DPyGetOpt.html
#http://www.artima.com/weblogs/viewpost.jsp?thread=4829
class Usage(Exception):
    def __init__(self, msg=None, err=True):
        #msg is an error message to post before the usage info
        usage="Usage: %s (Options)\n" % sys.argv[0]
        usage +="Options:\n"
        usage +="\t--dict  |-D=string : reference dictionary file, must be provided\n"
        usage +="\t--input |-I=string : input file, if unset, defaults to stdin\n"
        usage +="\t--output|-O=string : output file, if unset defaults to stdout\n"
        usage +="\t--help  |-h        : get this usage info\n"
        if msg is not None:
            self.msg = msg.strip() +"\n" + usage
        else:
            self.msg = usage
        self.exit_code=None
        if err == True:
            self.exit_code = 2
        else:
            self.exit_code = 0
def main(argv=None):
    inputOpt=None
    outputOpt=None
    dictOpt=None
    if argv is None:
        argv = sys.argv
    try:
        #try to parse option arguments
        try:
            opts=[]
            opts.append("input|I=s")
            opts.append("output|O=s")
            opts.append("dict|D=s")
            opts.append("help|h")
            opt_parser=DPyGetOpt.DPyGetOpt()
            opt_parser.setIgnoreCase(False)
            opt_parser.setAllowAbbreviations(False)
            opt_parser.setPosixCompliance(True)
            opt_parser.parseConfiguration(opts)
            opt_parser.processArguments(sys.argv)
            inputOpt=opt_parser.valueForOption("input")
            outputOpt=opt_parser.valueForOption("output")
            dictOpt=opt_parser.valueForOption("dict")
            help_flag=bool(opt_parser.valueForOption("help"))
            argv=opt_parser.freeValues
            if help_flag or len(argv) > 0 or (dictOpt is None):
                raise Usage(err=False)
        except DPyGetOpt.ArgumentError as DPyGetOptArgErr:
            raise Usage("DPyGetOptArgErr: " + DPyGetOptArgErr.__str__())
            pass
        except DPyGetOpt.SpecificationError as DPyGetOptSpecErr:
            raise Usage("DPyGetOptSpecErr: " + DPyGetOptSpecErr.__str__())
            pass
        except DPyGetOpt.TerminationError as DPyGetOptTermErr:
            raise Usage("DPyGetOptTermErr: " + DPyGetOptTermErr.__str__())
            pass
        except DPyGetOpt.Error as DPyGetOptErr:
            raise Usage("DPyGetOptErr: " + DPyGetOptErr.__str__())
            pass
    except Usage as err:
        sys.stderr.write(err.msg)
        return err.exit_code
    inputFile=None
    outputFile=None
    dictFile=open(dictOpt,'r')
    #read dict file
    contig_order=[]
    for line in dictFile:
        matchObj=re.match("^@SQ\\tSN:(.+)\\tLN:(.+)\\tUR:(.+)\\tM5(.+)$",line.strip())
        if matchObj:
            contig_order.append(matchObj.group(1))
    dictFile.close()
#    for item in contig_order:
#        sys.stderr.write("%s\n" % item)
    if inputOpt is None:
        inputFile=sys.stdin
    else:
        inputFile=open(inputOpt,'r')
    if outputOpt is None:
        outputFile=sys.stdout
    else:
        outputFile=open(outputOpt,'w')
    print ("inputFile: %s" % inputOpt)
    print ("outputFile: %s" % outputOpt)
    vcf_hash={}
    vcf_header=[]
    #read VCF file
    for line in inputFile:
        result=line.strip()
        if re.match("^#.+$",result):
            vcf_header.append(result)
        else:
            if result != "":
                splitresult=result.split("\t")
                if len(splitresult) != 8:
                    raise Exception("File does not adhere to VCF format (8 TAB columns)")
                contig=splitresult[0]
                start=int(splitresult[1])
                variant=("%sto%s" %(splitresult[3],splitresult[4]))
                if not vcf_hash.has_key(contig):
                    vcf_hash[contig]={}
                if not vcf_hash[contig].has_key(start):
                    vcf_hash[contig][start]={}
                if not vcf_hash[contig][start].has_key(variant):
                    vcf_hash[contig][start][variant]=[]
                vcf_hash[contig][start][variant].append(result)
                
    #close input
    if inputFile is not sys.stdin:
        inputFile.close()
    else:
        inputFile=None
    for item in vcf_header:
        outputFile.write("%s\n" % item)
    for contig in contig_order:
        if contig in vcf_hash:
#            outputFile.write("%s\n" % contig)
            for start in sorted(vcf_hash[contig].keys()):
#                outputFile.write("\t%s\n" % start)
                for variant in sorted(vcf_hash[contig][start].keys()):
#                    outputFile.write("\t\t%s\n" % variant)
                    for entry in vcf_hash[contig][start][variant]: 
#                        outputFile.write("\t\t\t%s\n" % entry)
                        outputFile.write("%s\n" % entry)
                
                
    outputFile.flush()
    #close output
    if outputFile is not sys.stdout:
        outputFile.close()
    else:
        outputFile=None
    return 0
if __name__ == "__main__":
    try:
        sys.exit(main())
    except exceptions.KeyboardInterrupt:
        sys.exit(1)