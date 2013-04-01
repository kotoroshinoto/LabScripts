#!/usr/bin/env python
'''
Created on Apr 1, 2013

@author: mgooch
'''
import sys,re
import BiotoolsSettings
import DPyGetOpt
import logging,traceback
def log_uncaught_exceptions(exception_type, exception, tb):

    logging.critical(''.join(traceback.format_tb(tb)))
    logging.critical('{0}: {1}'.format(exception_type, exception))

sys.excepthook = log_uncaught_exceptions
#http://ipython.org/ipython-doc/rel-0.10.2/html/api/generated/IPython.DPyGetOpt.html
#http://www.artima.com/weblogs/viewpost.jsp?thread=4829
class Usage(Exception):
    def __init__(self, msg=None, err=True):
        #msg is an error message to post before the usage info
        usage="Usage: %s (Options)\n" % sys.argv[0]
        usage +="Options:\n"
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
    if argv is None:
        argv = sys.argv
    try:
        #try to parse option arguments
        try:
            opts=[]
            opts.append("input|I=s")
            opts.append("output|O=s")
            opts.append("help|h")
            opt_parser=DPyGetOpt.DPyGetOpt()
            opt_parser.setIgnoreCase(False)
            opt_parser.setAllowAbbreviations(False)
            opt_parser.setPosixCompliance(True)
            opt_parser.parseConfiguration(opts)
            opt_parser.processArguments(sys.argv)
            inputOpt=opt_parser.valueForOption("input")
            outputOpt=opt_parser.valueForOption("output")
            help_flag=bool(opt_parser.valueForOption("help"))
            argv=opt_parser.freeValues
            if help_flag or len(argv) > 0:
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
    input=None
    output=None
    if inputOpt is None:
        input=sys.stdin
    else:
        input=open(inputOpt,'r')
    if outputOpt is None:
        output=sys.stdout
    else:
        output=open(outputOpt,'w')
    print ("input: %s" % inputOpt)
    print ("output: %s" % outputOpt)
    chroms={}
    for line in input:
        result=line.strip()
        if not (re.match("^#.+$",result)):
            splitresult=result.split("\t")
            if len(splitresult) != 8:
                raise Exception("File does not adhere to VCF format (8 TAB columns)")
            #output.write("%s\n" % splitresult[0])
            chroms[splitresult[0]]=True
#            if not(re.match("^chr.+$",splitresult[0])):
#                splitresult[0]="chr%s" % splitresult[0]
        #output.write(("%s\n" % result))
    for item in chroms:
        output.write("%s\n" % item)
if __name__ == "__main__":
    sys.exit(main())