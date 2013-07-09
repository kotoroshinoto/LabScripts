#!/usr/bin/env python
import sys
import os
import BiotoolsSettings
import DPyGetOpt
from Pipeline.PipelineTemplate import PipelineTemplate
import Pipeline.PipelineUtil as PipelineUtil
from Pipeline.PipelineError import PipelineError
from Pipeline.PipelineClusterJob import PipelineClusterJob

#http://ipython.org/ipython-doc/rel-0.10.2/html/api/generated/IPython.DPyGetOpt.html
#http://www.artima.com/weblogs/viewpost.jsp?thread=4829
class Usage(Exception):
    def __init__(self, msg=None, err=True):
        #msg is an error message to post before the usage info
        usage="Usage: %s (options)\n" % sys.argv[0]
        usage +="Options:\n"
        usage +="\t--template     |-T=string : set template name\n"
        usage +="\t--clearsuffixes|-C        : set flag to force suffix reset post-module\n"
        usage +="\t--cross        |-c        : set flag to inform SJM generator that this is a crossjob\n" 
        usage +="\t                           (depends on pairs of input files from different samples)\n"
        usage +="\t--variable     |-V=string : add pipeline variable to be used during variable replacement (multi-use)\n"
        usage +="\t--suffix       |-S=string : set suffix to be used post-module\n"
        usage +="\t--subjob       |-s=string : add a subjob to template\n"
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
            opts.append("variable|V=s@")
            opts.append("clearsuffixes|C")
            opts.append("suffix|S=s")
            opts.append("template|T=s")
            opts.append("subjob|J=s@")
            opts.append("cross|c")
            opts.append("help|h")
            opt_parser=DPyGetOpt.DPyGetOpt()
            opt_parser.setIgnoreCase(False)
            opt_parser.setAllowAbbreviations(False)
            opt_parser.setPosixCompliance(True)
            opt_parser.parseConfiguration(opts)
            opt_parser.processArguments(sys.argv)
            pipeline_vars=opt_parser.valueForOption("variable")
            pipeline_clearsuffixes=bool(opt_parser.valueForOption("clearsuffixes"))
            pipeline_crossjob=bool(opt_parser.valueForOption("cross"))
            pipeline_suffix=opt_parser.valueForOption("suffix")
            pipeline_templateName=opt_parser.valueForOption("template")
            pipeline_subjobs=opt_parser.valueForOption("subjob")
            help_flag=bool(opt_parser.valueForOption("help"))
            if help_flag:
                raise Usage(err=False)
            argv=opt_parser.freeValues
            print("defined vars:")
            if pipeline_vars is None:
                print("\t(No vars defined)")
            else:
                for var in pipeline_vars:
                    print("\t%s" % var)
            if pipeline_subjobs is None:
                raise Usage("Must define at least one subjob",err=True)
            else:
                print("defined subjob commands:")
                for job in pipeline_subjobs:
                    print("\t%s" % job)
            print("suffixes cleared after template:")
            print("\t%s" % pipeline_clearsuffixes)
            print("Is a CrossJob:")
            print("\t%s" % pipeline_crossjob)
            if pipeline_suffix is None:
                raise Usage("Must Specify a template suffix",err=True)
            print("Template Suffix:")
            print("\t%s" % pipeline_suffix)
            if pipeline_templateName is None:
                raise Usage("Must Specify a template name",err=True)
            print("Template Name:")
            print("\t%s" % pipeline_templateName)
            #TODO method stub
            temp=PipelineTemplate()
            temp.suffix=pipeline_suffix; 
            temp.clearsuffixes=pipeline_clearsuffixes;
            temp.isCrossJob=pipeline_crossjob;
            temp.name=pipeline_templateName;
            parseVars(temp,pipeline_vars);
            parseSubJobs(temp,pipeline_subjobs);
            #temp.ClusterJobs=[];
            #temp.vars={};
            #temp.var_keys=[];
            temp.writeTemplate()
        except DPyGetOpt.ArgumentError as DPyGetOptArgErr:
            raise Usage("DPyGetOptArgErr: " + DPyGetOptArgErr.__str__())
        except DPyGetOpt.SpecificationError as DPyGetOptSpecErr:
            raise Usage("DPyGetOptSpecErr: " + DPyGetOptSpecErr.__str__())
        except DPyGetOpt.TerminationError as DPyGetOptTermErr:
            raise Usage("DPyGetOptTermErr: " + DPyGetOptTermErr.__str__())
        except DPyGetOpt.Error as DPyGetOptErr:
            raise Usage("DPyGetOptErr: " + DPyGetOptErr.__str__())
        except PipelineError as pipe_err:
            print (pipe_err.msg);
            return -1;
        print("PROGRAM EXECUTION REACHED END OF MAIN")
        return 0;
    except Usage as err:
        sys.stderr.write(err.msg)
        sys.stderr.write("for help use --help")
        return err.exit_code
def parseVars(template,Vars):
    if template is None:
        raise PipelineError("[PipelineTemplateGenerator.parseVars] template object is None");
    if Vars is not None:        
        #print("Vars: %s" % Vars)
        for Var in Vars:
            eqsplit=Var.split("=")
            if (len(eqsplit)!=2):
                raise PipelineError("[PipelineTemplateGenerator.parseVars] Incorrect syntax for var definition: "+ Var);
            if eqsplit[0] in template.vars:
                raise PipelineError("[PipelineTemplateGenerator.parseVars] defined same var twice: "+ eqsplit[0]);
            template.vars[eqsplit[0]]=eqsplit[1];
            template.var_keys.append(eqsplit[0]);
#        print("var keys: %s" % template.var_keys)
#        print("vars: %s" % template.vars)
def parseSubJobs(template,subjobs):
    if template is None:
        raise PipelineError("[PipelineTemplateGenerator.parseVars] template object is None");
    if subjobs is None:
        raise PipelineError("[PipelineTemplateGenerator.parseVars] No subjobs provided");
    for subjobopt in subjobs:
        clusterjob=template.getNewClusterJob();
        parseSubJob(subjobopt,clusterjob)
def parseSubJob(subjobopt,clusterjob):
    #subjobvars={};
    commasplit=subjobopt.split(",");
    for commaItem in commasplit:
        eqsplit=commaItem.split("=")
        print("split on equal sign: %s" % eqsplit)
        if (len(eqsplit)!=2):
            raise PipelineError("[PipelineTemplateGenerator.parseVars] invalid argument syntax! should have 2 elements separated by '=', have: %d" % len(eqsplit));
        if eqsplit[0] is "order_after":
            print("found order_after!!!")
            if ':' in eqsplit[1]:
                arr=eqsplit[1].split(":");
                print("split order after: %s" % arr)
                clusterjob.order_after.append(arr)
            else:
                print("order after: %s" % eqsplit[1])
                clusterjob.order_after.append(eqsplit[1])
        elif eqsplit[0] is "cmd":
            print("found cmd!!!")
            print("split cmd: %s" % eqsplit[1])
            clusterjob.cmd.append(eqsplit[1]);
        else:
            print("found %s!!!" % eqsplit[0])
            setattr(clusterjob, eqsplit[0], eqsplit[1])
        if clusterjob.module is None:
            clusterjob.module=BiotoolsSettings.getValue("MODULEFILE")
        if clusterjob.directory is None:
            clusterjob.directory=BiotoolsSettings.getValue("CURDIR")
        if clusterjob.queue is None:
            clusterjob.queue=BiotoolsSettings.getValue("JOBQUEUE")
    return None
if __name__ == "__main__":
    sys.exit(main())