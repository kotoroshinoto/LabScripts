#!/usr/bin/env python
import sys,os,re
import Pipeline.settings.BiotoolsSettings as BiotoolsSettings 
import DPyGetOpt
import pyswitch
import igraph
from Pipeline.core.AnalysisPipeline import PipelineNode
from Pipeline.core.AnalysisPipeline import AnalysisPipeline
from Pipeline.core.PipelineError import PipelineError
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
        usage +="\t--list|-L     : path to text file containing a list of files that will be run through pipeline !!Specific format required!!\n" 
        usage +="\t--help|-h     : prints this help menu\n"
        usage +="SJM file behavior: (values must be either 'join' or 'split')\n"
        usage +="\t--sampleOpt|-S=value\n"
        usage +="\t\tif join: SJM text for all Samples will be merged into 1 sjm file\n"
        usage +="\t\tif split: SJM text for each Sample will be output to separate files\n"
        usage +="\t--stepOpt|-s=value\n"
        usage +="\t\tif join: SJM text for all Steps will be merged into 1 sjm file\n"
        usage +="\t\tif split: SJM text for each Step will be output to separate files\n"
        usage +="\t--pairOpt|-p=value\n"
        usage +="\t\tif join: Jobs that use pairs of files will keep all text for pairs together\n"
        usage +="\t\tif split: Jobs that use pairs of files will produce 1 SJM file for each pairing\n"
        usage +="--sampleOpt will have no effect on paired steps\n"
        usage +="these effects can stack, if all are set to join, only 1 sjm file will be produced, containing all jobs\n"
        usage +="if you split pairs, but join Steps or join Samples, remember that a split will still occur at any point where a paired template is placed\n"
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
            opts.append("list|l=s")
            opts.append("stepOpt|s=s")
            opts.append("sampleOpt|S=s")
            opts.append("pairOpt|p=s")
            opts.append("help|h")
            opt_parser=DPyGetOpt.DPyGetOpt()
            opt_parser.setIgnoreCase(False)
            opt_parser.setAllowAbbreviations(False)
            opt_parser.setPosixCompliance(True)
            opt_parser.parseConfiguration(opts)
            opt_parser.processArguments(sys.argv)
            pipeline_opt=opt_parser.valueForOption("pipeline")
            list_opt=opt_parser.valueForOption("list")
            sampleOpt=opt_parser.valueForOption("sampleOpt")
            stepOpt=opt_parser.valueForOption("stepOpt")
            pairOpt=opt_parser.valueForOption("pairOpt")
            if sampleOpt is None:
                sampleOpt='join'
            else:
                sampleOpt=sampleOpt.lower()
            if stepOpt is None:
                stepOpt='split'
            else:
                stepOpt=stepOpt.lower()
            if pairOpt is None:
                pairOpt='join'
            else:
                pairOpt=pairOpt.lower()
            help_flag=bool(opt_parser.valueForOption("help"))
#            print(pipeline_opt)
#            print(list_opt)
#            print(pairs_opt)
#            print(joinSamples_opt)
#            print(joinSteps_opt)
#            print(splitCompare_opt)
#            print(help_flag)
            if help_flag:
                raise Usage("",err=False)
            argv=opt_parser.freeValues
            if not(pipeline_opt):
                raise Usage("pipeline argument is required")
            if not(list_opt):
                raise Usage("list argument is required")
            if not(sampleOpt == 'split' or sampleOpt == 'join'):
                raise Usage("invalid value for --sampleOpt")
            if not(stepOpt == 'split' or stepOpt == 'join'):
                raise Usage("invalid value for --stepOpt")
            if not(pairOpt == 'split' or pairOpt == 'join'):
                raise Usage("invalid value for --pairOpt")
            print("sample option: %s" % sampleOpt)
            print("step option: %s" % stepOpt)
            print("pair option: %s" % pairOpt)
            pipeline=parsePipelineOpt(pipeline_opt)
            pipeline.loadSampleData(list_opt)
            output=pipeline.toSJMStrings(sampleOpt=='split', stepOpt =='split', pairOpt == 'split')
            writeFiles(output)
#             pipeline.templategraph.write("/dev/stdout","graphml")
        except DPyGetOpt.ArgumentError as DPyGetOptArgErr:
            raise Usage("DPyGetOptArgErr: " + DPyGetOptArgErr.__str__())
        except DPyGetOpt.SpecificationError as DPyGetOptSpecErr:
            raise Usage("DPyGetOptSpecErr: " + DPyGetOptSpecErr.__str__())
        except DPyGetOpt.TerminationError as DPyGetOptTermErr:
            raise Usage("DPyGetOptTermErr: " + DPyGetOptTermErr.__str__())
        except DPyGetOpt.Error as DPyGetOptErr:
            raise Usage("DPyGetOptErr: " + DPyGetOptErr.__str__())
        except PipelineError as pipe_err:
            sys.stderr.write(pipe_err.msg);
            return -1;
        print("PROGRAM EXECUTION REACHED END OF MAIN")
        return 0;
    except Usage as err:
        sys.stderr.write(err.msg)
        return err.exit_code
def splitJobspec(jobspec):
    #TODO: name format is TemplateName[SubName]
    _jobspec=jobspec.strip();
    brack_op= jobspec.count('[')
    brack_cl= jobspec.count(']')
    brace_op= jobspec.count('{')
    brace_cl= jobspec.count('{')
    if (((brack_op==1) and (not (brack_cl==1))) or ((not (brack_op==1)) and (brack_cl==1))) or (((brace_op==1) and (not (brace_cl==1))) or ((not (brace_op==1)) and (brace_cl==1))):
        raise PipelineError("[Pipeline.AnalysisPipeline] improper format for jobspec: unpaired brace or bracket")
    if brack_op >1 or brack_cl >1 or brace_op >1 or brace_cl >1:
        raise PipelineError("[Pipeline.AnalysisPipeline] improper format for jobspec: more than one of: '[]{}'")
    brack=brack_op == 1 and brack_cl == 1
    brace=brace_op == 1 and brace_cl == 1
    if brace:
        brace_start=_jobspec.find('{')
        brace_end=_jobspec.find('}')
        if brace_end < brace_start:
            raise PipelineError("[Pipeline.AnalysisPipeline] improper format for jobspec: } before {")
    if brack:
        brack_start=_jobspec.find('[')
        brack_end=_jobspec.find(']')
        if brack_end < brack_start:
            raise PipelineError("[Pipeline.AnalysisPipeline] improper format for jobspec: ] before [")
    result={}
    if brace and brack:
        brace_start=_jobspec.find('{')
        brace_end=_jobspec.find('}')
        brack_start=_jobspec.find('[')
        brack_end=_jobspec.find(']')
        # if brace start is after bracket end, no overlaps should be present, and order should be correct
        if brace_start < brack_end :#other conditions covered by other checks
            raise PipelineError("[Pipeline.AnalysisPipeline] improper format for jobspec: {} was before [] or overlapped ")
        bothmatch=re.match("^(.*)\[(.*)\]\{(.*)\}$",_jobspec)
        if bothmatch:
            result['template']=bothmatch.group(1).upper()
            result['subname']=bothmatch.group(2).upper()
            result['optionfile']=bothmatch.group(3)
            return result
        else:
            raise PipelineError("[Pipeline.AnalysisPipeline] problem parsing jobspec[]{}:%s}" % jobspec  )
    elif brack:
        brackmatch=re.match("^(.*)\[(.*)\]$",_jobspec)
        if brackmatch:
            result['template']=brackmatch.group(1).upper()
            result['subname']=brackmatch.group(2).upper()
            result['optionfile']=""
            return result
        else:
            raise PipelineError("[Pipeline.AnalysisPipeline] problem parsing jobspec[]:%s}" % jobspec  )
    elif brace:
        bracematch=re.match("^(.*)\{(.*)\}$",_jobspec)
        if bracematch:
            result['template']=bracematch.group(1).upper()
            result['subname']=""
            result['optionfile']=bracematch.group(2)
            return result
        else:
            raise PipelineError("[Pipeline.AnalysisPipeline] problem parsing jobspec{}:%s}" % jobspec  )
    else:
        result['template']=jobspec.upper()
        result['subname']=""
        result['optionfile']=""
        return result
def parsePipelineOpt(pipelineOpt):
    pipeline=AnalysisPipeline()
    for item in pipelineOpt.split(","):
        previous=None
        for spec in item.strip().split("-"):
            current=splitJobspec(spec)
            pipeline.getNodeWithDict(current)
            if previous:
                pipeline.linkNodes(previous['template'], previous['subname'], current['template'], current['subname'])
#                 print ("%s|%s -> %s|%s" % (previous['template'], previous['subname'], current['template'], current['subname']))
#             else:
#                 print ("-> %s|%s" % (current['template'], current['subname']))
            previous=current
#         print("-----------")
#             pipeline.getNodeWithDict(splitJobspec(spec))
    return pipeline
def writeFiles(output):
    if len(output.keys()) == 0:
        raise PipelineError("Error: No files were produced")
    for filename in output.keys():
#         open()
        print("writing %s" % filename)
if __name__ == "__main__":
    sys.exit(main())