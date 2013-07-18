'''
Created on Mar 18, 2013

@author: Gooch
'''
import Pipeline.settings.BiotoolsSettings as BiotoolsSettings
import re,os
from Pipeline.core.PipelineTemplate import PipelineTemplate
import Pipeline.core.PipelineUtil as PipelineUtil
from Pipeline.core.PipelineError import PipelineError

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
        self.nodes={}#info about nodes stored in PipelineNode object in this dictionary
        #index with template[subname]
        #only allow first specification to contain optionfile, blank != ""
        #allows for easier start point of new branches.
        self.templategraph= igraph.Graph(directed=True)
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
                raise PipelineError("[PipelineTemplate.AnalysisPipeline] requested template does not exist: %s\n" % template)
        else:
            return self.jobtemplates.get(template.upper())
        
    def getNode(self,template,subname,optionfile):
        vertName=""
        if(subname):
            vertName="%s|%s" % (template.upper(),subname.upper())
        else:
            vertName="%s" % (template.upper())
        print ("using vertex name: '%s'" % vertName)
        #check if node already exists (template,subname)
        if self.nodes.has_key(vertName):
            node=self.nodes.get(vertName)
            if (node.subname.upper() != subname.upper()) or (node.template.name.upper() != template.upper()):
                raise PipelineError("[PipelineTemplate.AnalysisPipeline] template in expected location did not match\n")
            #if it does make sure optionfile matches or is blank or None,
            if optionfile != node.optionfile:
                #otherwise mismatch is an error
                raise PipelineError("[PipelineTemplate.AnalysisPipeline] matched template & subname, but mismatched optionfile\n")
            #if it does return it
            return node
        #if it doesnt, create it
        newNode=PipelineNode(self)
        newNode.template=self.getTemplate(template)
        newNode.subname=subname
        newNode.optionfile=optionfile
        self.nodes[vertName]=newNode
        self.templategraph.add_vertex(name=vertName,data=newNode)
        return newNode
    
    def linkNodes(self,source_name,source_subname,sink_name,sink_subname):
        #add edge linking nodes
        sourceVertName=""
        sinkVertName=""
        if(source_subname):
            sourceVertName="%s|%s" % (source_name.upper(),source_subname.upper())
        else:
            sourceVertName="%s" % (source_name.upper())
        print ("source vertex name: '%s'" % sourceVertName)
        if(sink_subname):
            sinkVertName="%s|%s" % (sink_name.upper(),sink_subname.upper())
        else:
            sinkVertName="%s" % (sink_name.upper())
        print ("sink vertex name: '%s'" % sinkVertName)
        self.templategraph.add_edge(sourceVertName,sinkVertName)
    def getSourceNodes(self):
        #return list of all nodes that aren't targets of other nodes
        degrees=self.templategraph.indegree()
        result=[]
        for i in range(0,len(degrees)):
            if not degrees[i]:
                result.append(self.templategraph.vs[i].attributes()['name'])
        return result
    
    def getSinkNodes(self):
        #return list of all nodes that don't have targets
        degrees=self.templategraph.outdegree()
        result=[]
        for i in range(0,len(degrees)):
            if not degrees[i]:
                result.append(self.templategraph.vs[i].attributes()['name'])
        return result
    
    def toSJMStrings(self,sampleSplit=False,templateSplit=True):
        sjm_strings={}
        #produce strings in fully split form
        #get source nodes
        #starting with each source node, and tracing the tree parent-first, then children:
            #use templates to get SJM content,
            #track cumulative suffixes
        #join strings as appropriate:
        if sampleSplit and templateSplit:
            #split between samples AND between
            return None
        elif sampleSplit:
            #split between samples
            #add any extra link-related job dependencies manually
            return None
        elif templateSplit:
            #split only between templates
            return None
        else:
            #one giant file
            #add any extra link-related job dependencies manually
            return None
        #add sjm logfile location to end of each file
        return sjm_strings
#apl=AnalysisPipeline()
#worked=apl.loadTemplate("BWA_ALIGN_PAIRED")
#print (apl.TemplateIsLoaded("BWA_ALIGN_PAIRED"))
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toTemplateString())
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toString('grouplbl','.cumsuffix','prefix'))