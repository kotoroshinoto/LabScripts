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
        self.optionfiles={}
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
                result.append(self.templategraph.vs[i].attributes()['data'])
        return result
    
    def getSinkNodes(self):
        #return list of all nodes that don't have targets
        degrees=self.templategraph.outdegree()
        result=[]
        for i in range(0,len(degrees)):
            if not degrees[i]:
                result.append(self.templategraph.vs[i].attributes()['data'])
        return result
    def getParentOfNode(self,node):
        source_name=node.template.name
        source_subname=node.subname
        sourceVertName=""
        if(source_subname):
            sourceVertName="%s|%s" % (source_name.upper(),source_subname.upper())
        else:
            sourceVertName="%s" % (source_name.upper())
        sourceVert=self.templategraph.vs.find(name=sourceVertName)
        parentList=sourceVert.predecessors()
        if len(parentList) > 1:
            raise PipelineError("[PipelineTemplate.AnalysisPipeline.getParentOfNode] graph indicates node does not only have 1 parent")
        if len(parentList) == 0:
            return None
        return parentList[0].attributes()['data']
    def getTargetsOfNode(self,node):
        source_name=node.template.name
        source_subname=node.subname
        sourceVertName=""
        result=[]
        if(source_subname):
            sourceVertName="%s|%s" % (source_name.upper(),source_subname.upper())
        else:
            sourceVertName="%s" % (source_name.upper())
        sourceVert=self.templategraph.vs.find(name=sourceVertName)
        for node in sourceVert.successors():
            result.append(node.attributes()['data'])
        
        return result
    def toSJMStrings(self,splitOpts,baseName,grouplbl):
        sjm_strings={}
        #get name of string content should be added to:
        nodeQueue=[]
        cumsuffixQueue=[]
        #set starting nodes
        for item in self.getSourceNodes():
            nodeQueue.append(item)
            cumsuffixQueue.append("")
        while len(nodeQueue) > 0:
            node=nodeQueue.pop(0)
            cumsuffix=cumsuffixQueue.pop(0)
            #if job is comparing pairs of samples,
            if node.template.isCrossJob:
                raise PipelineError("[PipelineTemplate.AnalysisPipeline.toSJMStrings] CrossJob Translation not yet implemented")
                #handle selected pairs
                #TODO, what to do with no selection (missing optionfile)? Fail or do ALL pairwise?
            else:
                #otherwise translate template once per file
                for sample in self.samples.keys():
                    Sample=self.samples[sample]
                    stringName=self.getFileNameForString(splitOpts,baseName, node, Sample)
                    if not (sjm_strings.has_key(stringName)):
                        sjm_strings[stringName]=""
                    parentNode=self.getParentOfNode(node)
                    #TODO get template string & append it to sjm_strings[stringName]
                    sjm_strings[stringName]+=node.template.toString(grouplbl,cumsuffix,Sample.ID)
                    #TODO add any extra link-related job dependencies manually
                    if parentNode is not None: 
                        print("%s <<< %s | %s <- %s | % s : %s" % (stringName, node.template.name,node.subname,parentNode.template.name,parentNode.subname, Sample.ID))
                    else:
                        print("%s <<< %s | %s : %s" % (stringName, node.template.name,node.subname,Sample.ID))
            for item in self.getTargetsOfNode(node):
                nodeQueue.append(item)
                if node.template.clearsuffixes:
                    cumsuffixQueue.append("")
                else:
                    cumsuffixQueue.append(cumsuffix+node.template.suffix)
        return sjm_strings
        #produce strings in fully split form
        #get source nodes
        #starting with each source node, and tracing the tree parent-first, then children:
            #use templates to get SJM content,
            #track cumulative suffixes
        #join strings as appropriate:
        if splitOpts['sample'] and splitOpts['step']:
            #split between samples AND between
            return dict()
        elif splitOpts['sample']:
            #split between samples
            
            return dict()
        elif splitOpts['step']:
            #split only between templates
            return dict()
        else:
            #one giant file
            #add any extra link-related job dependencies manually
            return dict()
        #add sjm logfile location to end of each file
        return sjm_strings
    def getFileNameForString(self,splitOpts,baseName,node=None,sample=None):
        if splitOpts['sample'] and splitOpts['step']:
            #split between samples AND between
            if node.subname:
                return "%s.%s.%s.sjm" % (baseName,node.template.name,sample.ID)
            else:
                return "%s.%s.%s.%s.sjm" % (baseName,node.template.name,node.subname,sample.ID)
        elif splitOpts['sample']:
            #split between samples
            #add any extra link-related job dependencies manually
            return "%s.%s.sjm" % (baseName,sample.ID)
        elif splitOpts['step']:
            #split only between templates
            if node.subname:
                return "%s.%s.%s.sjm" % (baseName,node.template.name,node.subname)
            else:
                return "%s.%s.sjm" % (baseName,node.template.name)
        else:
            #one giant file
            #add any extra link-related job dependencies manually
            return "%s.sjm" % baseName
    def recursiveVertToString(self,strings,splitOpts,baseName,grouplbl,node,cumsuffix):
        
        #split on templates but keep samples together, join pairs
        if node.template.isCrossJob:
            derp=""
        else:
            #get one string for each file
            for sample in self.samples.keys():
                mystring=node.template.toString(grouplbl,cumsuffix,sample.source1,sample.source2)
            for nextnode in self.getTargetsOf(node.template.name,node.subname):
                if node.clearsuffixes:
                    mystring+=self.recursiveVertToString(nextnode,strings,grouplbl,node.template.suffix)
                else:
                    mystring+=self.recursiveVertToString(nextnode,strings,grouplbl,cumsuffix+node.template.suffix)
        #if templates are joined, append extra order_after strings
        if(splitOpts['step']):
            derp=""
#apl=AnalysisPipeline()
#worked=apl.loadTemplate("BWA_ALIGN_PAIRED")
#print (apl.TemplateIsLoaded("BWA_ALIGN_PAIRED"))
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toTemplateString())
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toString('grouplbl','.cumsuffix','prefix'))