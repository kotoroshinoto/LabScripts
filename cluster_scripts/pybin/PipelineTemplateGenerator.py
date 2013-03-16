#!/usr/bin/env python
import sys
import os
import BiotoolsSettings
BiotoolsSettings.AssertPaths()
import DPyGetOpt
import pyswitch
def usage(exit_code=0):
    usage="Usage: %s (options)\n" % sys.argv[0]
    usage +="Options:\n"
    usage +="\t--template|-T=string : set template name\n"
    usage +="\t--clearsuffixes|-C   : set flag to force suffix reset post-module\n"
    usage +="\t--cross|-c           : set flag to inform SJM generator that this is a crossjob\n" 
    usage +="\t                       (depends on pairs of input files from different samples)\n"
    usage +="\t--variable|-V=string : add pipeline variable to be used during variable replacement (multi-use)\n"
    usage +="\t--suffix|-S=string   : set suffix to be used post-module\n"
    usage +="\t--subjob|-s=string   : add a subjob to template\n"
    sys.stderr.write(usage)
    sys.exit(exit_code)

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
help_flag=bool(opt_parser.valueForOption("help"))
if help_flag:
    usage(exit_code=0)
argv=opt_parser.freeValues
