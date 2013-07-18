'''
Created on Mar 18, 2013

@author: Gooch
'''
import sys
if 'Pipeline.pyz' in sys.argv[0]:
    sys.path.append('/UCHC/HPC/Everson_HPC/cluster_scripts/pybin/Pipeline.pyz')
import Pipeline.commands.PipelineTemplateGenerator
import Pipeline.commands.PipelineGenerateSJM
def main():
    sys.stderr.write("This is currently a placeholder, it will eventually be implemented to forward commandline args to the appropriate python module\n")
    sys.stderr.write("args: '%s'\n" % (' '.join(sys.argv)))
    if(len(sys.argv) == 1 ):
        sys.stderr.write("no arguments given\n")
        sys.stderr.write("options are\n")
        sys.stderr.write("template: create new template\n")
        sys.stderr.write("pipeline: use templates to construct a pipeline\n")
    if (sys.argv[1].lower() == "template"):
        Pipeline.commands.PipelineTemplateGenerator.main(sys.argv)
    elif (sys.argv[1].lower() == "pipeline"):
        Pipeline.commands.PipelineGenerateSJM.main(sys.argv)
    return 0
if __name__ == '__main__':
    sys.exit(main())