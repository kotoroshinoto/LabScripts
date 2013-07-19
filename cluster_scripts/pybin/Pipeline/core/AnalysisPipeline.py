'''
Created on Mar 18, 2013

@author: Gooch
'''
import Pipeline.settings.BiotoolsSettings as BiotoolsSettings
import re,os
from Pipeline.core.PipelineTemplate import PipelineTemplate
import Pipeline.core.PipelineUtil as PipelineUtil
from Pipeline.core.PipelineError import PipelineError
from Pipeline.core.PipelineSampleData import SampleData

import igraph
class PipelineNode:
    def __init__(self,pipeline):
        #TODO: fill in stub
        self.pipeline=pipeline
        self.template=None
        self.subname=None
        self.optionfile=None
    def setValues(self,templatename,subname=None,optionfile=None):
        self.subname=subname.upper()
        self.template=self.pipeline.getTemplate(templatename.upper())
        self.loadOptionFile(optionfile)        
    def loadOptionFile(self,filename):
        #TODO empty method stub
        self.optionfile=filename
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
        self.samples=None
    def loadSampleData(self,filename):
        self.samples=SampleData.readBatch(filename)
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
        return self.jobtemplates.get(template.upper())
        
    def getNode(self,template,subname,optionfile):
#         print("searching for:")
#         print ("\ttemplate: %s" % template)
#         print ("\tsubname: %s" % subname)
#         print ("\toptionfile: %s" % optionfile)
        vertName=""
        if(subname):
            vertName="%s|%s" % (template.upper(),subname.upper())
        else:
            vertName="%s" % (template.upper())
#         print ("using vertex name: '%s'" % vertName)
        #check if node already exists (template,subname)
        if self.nodes.has_key(vertName):
#             print ("getting existing node")
            node=self.nodes.get(vertName)
            if node:
                subnames_match=node.subname.upper() == subname.upper()
                
#                 print ("\ttemplate: %s" % node.template)
#                 print ("\tsubname: %s" % node.subname)
#                 print ("\toptionfile: %s" % node.optionfile)
                names_match=node.template.name.upper() == template.upper()
                if not(subnames_match and names_match):
                    raise PipelineError("[PipelineTemplate.AnalysisPipeline] template in expected location did not match\n")
            #if it does make sure optionfile matches or is blank or None,
            if optionfile != node.optionfile:
                #otherwise mismatch is an error
                raise PipelineError("[PipelineTemplate.AnalysisPipeline] matched template & subname, but mismatched optionfile\n")
            #if it does return it
            return node
        #if it doesnt, create it
#         print("creating new node")
        newNode=PipelineNode(self)
        newNode.setValues(template,subname,optionfile)
#         print ("\ttemplate: %s" % newNode.template)
#         print ("\tsubname: %s" % newNode.subname)
#         print ("\toptionfile: %s" % newNode.optionfile)
#         newNode.template=self.getTemplate(template)
#         newNode.subname=subname
#         newNode.optionfile=optionfile
        self.nodes[vertName]=newNode
        self.templategraph.add_vertex(name=vertName,data=newNode)
        return newNode
    def getNodeWithDict(self,data):
        if not isinstance(data,dict):
            raise PipelineError("[PipelineTemplate.AnalysisPipeline.getNodeWithDict] gave wrong type: %s" % type(data))
        if not(data.has_key('template') and data.has_key('subname') and data.has_key('optionfile')):
            raise PipelineError("[PipelineTemplate.AnalysisPipeline.getNodeWithDict] missing an entry, has:(template:%s,subname:%s,optionfile:%s)\n" %(data.has_key('template') , data.has_key('subname') , data.has_key('optionfile')))
        return self.getNode(data['template'], data['subname'], data['optionfile'])
    def linkNodes(self,source_name,source_subname,sink_name,sink_subname):
        #add edge linking nodes
        sourceVertName=""
        sinkVertName=""
        if(source_subname):
            sourceVertName="%s|%s" % (source_name.upper(),source_subname.upper())
        else:
            sourceVertName="%s" % (source_name.upper())
#         print ("source vertex name: '%s'" % sourceVertName)
        if(sink_subname):
            sinkVertName="%s|%s" % (sink_name.upper(),sink_subname.upper())
        else:
            sinkVertName="%s" % (sink_name.upper())
#         print ("sink vertex name: '%s'" % sinkVertName)
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
    
    def getTargetsOf(self,source_name,source_subname):
        sourceVertName=""
        result=[]
        if(source_subname):
            sourceVertName="%s|%s" % (source_name.upper(),source_subname.upper())
        else:
            sourceVertName="%s" % (source_name.upper())
        sourceVert=self.templategraph.vs.find(name=sourceVertName)
        for node in sourceVert.successors():
            result.append(node.attributes()['name'])            
        
        return result
    def toSJMStrings(self,sampleSplit=False,templateSplit=True,splitCompares=False):
        sjm_strings={}
        #produce strings in fully split form
        #get source nodes
        #starting with each source node, and tracing the tree parent-first, then children:
            #use templates to get SJM content,
            #track cumulative suffixes
        #join strings as appropriate:
        if sampleSplit and templateSplit:
            #split between samples AND between
            return dict()
        elif sampleSplit:
            #split between samples
            #add any extra link-related job dependencies manually
            return dict()
        elif templateSplit:
            #split only between templates
            return dict()
        else:
            #one giant file
            #add any extra link-related job dependencies manually
            return dict()
        #add sjm logfile location to end of each file
        return sjm_strings
#apl=AnalysisPipeline()
#worked=apl.loadTemplate("BWA_ALIGN_PAIRED")
#print (apl.TemplateIsLoaded("BWA_ALIGN_PAIRED"))
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toTemplateString())
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toString('grouplbl','.cumsuffix','prefix'))