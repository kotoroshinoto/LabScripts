#!/usr/bin/env python
import sys
import os
import BiotoolsSettings
import DPyGetOpt
import pyswitch
import igraph
#http://ipython.org/ipython-doc/rel-0.10.2/html/api/generated/IPython.DPyGetOpt.html
#http://www.artima.com/weblogs/viewpost.jsp?thread=4829
#TODO: option for --splitSOLO , sjm generation will result in separate *.sjm files for each input file,
#TODO ^has no effect on crossjobs (change to join, split is default)
#TODO: option for --splitSTEPS , sjm generation will result in separate *.sjm files for each step (Template)
#TODO ^above 2 can be combined to split generated sjm files across samples AND steps (change to join, split is default)
#TODO: option for --splitCROSS, generate a separate sjm file for each pairing
#TODO ^ should only be used if cross step is set up so that any required SOLO substeps are in a 
#TODO: separate template and run prior to the CROSS step; program will blindly assume all cross steps are truly crossed 
#TODO ^ (thus it might run the same SOLO sub-commands more than once, resulting in conflicts)
class Usage(Exception):
    def __init__(self, msg, err=True):
        #msg is an error message to post before the usage info
        usage="Usage: %s (options)\n" % sys.argv[0]
        usage +="Options:\n"
        usage +="\t--pipeline|-P : list of steps to run IN ORDER\n" 
        usage +="\t--list|-L     : list of files that will be run through pipeline !!Specific format required!!\n" 
        usage +="\t--pairs|-p    : file with list of sample pairs (only affects steps that use sample pairing)\n"
        usage +="\t--help|-h     : prints this help menu\n"
        usage +="Options not yet implemented:\n"
        usage +="\t--joinSamples|-j   : SJM files for all Samples* will be merged into 1 sjm file**\n"
        usage +="\t--joinSteps|-J     : SJM files for all Steps will be merged into 1 sjm file**\n"
        usage +="\t--splitCompares|-S : Jobs that use pairs of files will produce 1 SJM file for each pairing instead of 1-per-step***\n"
        usage +="*  -joinSamples will have no effect on paired steps, they're already joined by default\n"
        usage +="** -these effects can stack, if both flags are set, only 1 sjm file will be produced, containing all jobs\n"
        usage +="***-cannot use splitCompares with joinSteps or joinSamples, will cause an exception\n"
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
    if argv is None:
        argv = sys.argv
    try:
        #try to parse option arguments
        try:
            opts=[]
            opts.append("pipeline|P=s")
            opts.append("list|L=s")
            opts.append("pairs|p=s")
            opts.append("joinSamples|j")
            opts.append("joinSteps|J")
            opts.append("splitCompares|S")
            opts.append("help|h")
            opt_parser=DPyGetOpt.DPyGetOpt()
            opt_parser.setIgnoreCase(False)
            opt_parser.setAllowAbbreviations(False)
            opt_parser.setPosixCompliance(True)
            opt_parser.parseConfiguration(opts)
            opt_parser.processArguments(sys.argv)
            pipeline_opt=opt_parser.valueForOption("pipeline")
            list_opt=opt_parser.valueForOption("list")
            pairs_opt=opt_parser.valueForOption("pairs")
            joinSamples_opt=bool(opt_parser.valueForOption("joinSamples"))
            joinSteps_opt=bool(opt_parser.valueForOption("joinSteps"))
            splitCompare_opt=bool(opt_parser.valueForOption("splitCompares"))
            help_flag=bool(opt_parser.valueForOption("help"))
#            print(pipeline_opt)
#            print(list_opt)
#            print(pairs_opt)
#            print(joinSamples_opt)
#            print(joinSteps_opt)
#            print(splitCompare_opt)
#            print(help_flag)
            if help_flag:
                raise Usage(err=False)
            argv=opt_parser.freeValues
            
            
            templategraph= igraph.Graph()
            templategraph.is_dag()#job tree must be a dag, 
        except DPyGetOpt.ArgumentError as DPyGetOptArgErr:
            raise Usage("DPyGetOptArgErr: " + DPyGetOptArgErr.__str__())
        except DPyGetOpt.SpecificationError as DPyGetOptSpecErr:
            raise Usage("DPyGetOptSpecErr: " + DPyGetOptSpecErr.__str__())
        except DPyGetOpt.TerminationError as DPyGetOptTermErr:
            raise Usage("DPyGetOptTermErr: " + DPyGetOptTermErr.__str__())
        except DPyGetOpt.Error as DPyGetOptErr:
            raise Usage("DPyGetOptErr: " + DPyGetOptErr.__str__())
        raise Usage("")
    except Usage as err:
        sys.stderr.write(err.msg)
        return err.exit_code
        
if __name__ == "__main__":
    sys.exit(main())