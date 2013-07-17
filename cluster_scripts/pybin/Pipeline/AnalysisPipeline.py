'''
Created on Mar 18, 2013

@author: Gooch
'''
import BiotoolsSettings
import re
import os
from Pipeline.PipelineTemplate import PipelineTemplate
import Pipeline.PipelineUtil as PipelineUtil
from Pipeline.PipelineError import PipelineError

import igraph
class PipelineNode:
    def __init__(self,pipeline):
        #TODO: fill in stub
        self.pipeline=pipeline
        self.template=None
        self.subname=None
        self.optionfile=None
    def setValues(self,templatename,subname=None,optionfile=None):
        if (subname is None) and (optionfile is None):
            self.template=self.pipeline.getTemplate("%s" % (templatename.upper() ))
        elif (subname is not None) and (optionfile is not None):
            self.template=self.pipeline.getTemplate("%s[%s]{%s}" % (templatename.upper(),subname.upper(),optionfile))
        elif (subname is not None) and (optionfile is None):
            self.template=self.pipeline.getTemplate("%s[%s]" % (templatename.upper(),subname.upper()))
        elif (subname is None) and (optionfile is not None):
            self.template=self.pipeline.getTemplate("%s{%s}" % (templatename.upper(),optionfile))
    def loadOptionFile(self):
        #TODO empty method stub
        return None
class AnalysisPipeline:
    def __init__(self):
        #TODO: fill in stub
        self.jobtemplates={}
        #list of nodes in tree
        self.nodes={}
        #index with template[subname]
        #only allow first specification to contain optionfile, blank != ""
        #allows for easier start point of new branches.
        self.templategraph= igraph.Graph()
        self.templategraph.is_dag()
    def loadTemplate(self,templateName):
        template=None
        #TODO: fill in stub
        if len(templateName) == 0:
            return False
        #check if step template is already loaded
        if templateName.upper() in self.jobtemplates:
            #if loaded, no more work to do
            return True;
        #if not found, check if template exists
        path2Template=os.path.join(PipelineUtil.templateDir(),templateName.upper()+".sjt")
        #print(path2Template)
        if os.path.isfile(path2Template):
            #if template exists
            template=PipelineTemplate.readTemplate(templateName.upper())
            self.jobtemplates[templateName.upper()]=template
            return True
        else:
            #if template doesn't exist, signal error
            return False
    def TemplateIsLoaded(self,template):
        return (template.upper() in self.jobtemplates)
    def getTemplate(self,template):
        if not self.TemplateIsLoaded(template):
            self.loadTemplate(template)
            if not self.TemplateIsLoaded(template):
                return None
        else:
            return self.jobtemplates.get(template.upper())
        
    def getNode(self,template,subname,optionfile):
        #todo derp
        #check if node already exists (template,subname)
        #if it does make sure optionfile matches or is blank or None,
            #if it does return it 
            #otherwise mismatch is an error
        #if it doesnt, create it
        if(subname):
            self.templategraph.add_vertex(name="%s_%s" % (template,subname))
        else:
            self.templategraph.add_vertex(name="template")
        return None
    
    def linkNodes(self,source_jobspec,sink):
        return None
    
    def getSourceNodes(self):
        return None
    
    def getSinkNodes(self):
        return None
#apl=AnalysisPipeline()
#worked=apl.loadTemplate("BWA_ALIGN_PAIRED")
#print (apl.TemplateIsLoaded("BWA_ALIGN_PAIRED"))
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toTemplateString())
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toString('grouplbl','.cumsuffix','prefix'))