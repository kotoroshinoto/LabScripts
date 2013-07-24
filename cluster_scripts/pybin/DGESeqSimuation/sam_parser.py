"""
sam_parser.py script
Version 2013.07.23

@author: Bing
run location: ssh mgooch@sig2-glx.cam.uchc.edu
run command: samtools view /UCHC/Everson/umar/cluster/align_bam/RNA_Pt5/NC5R_aligned_clean.bam | python /UCHC/HPC/Everson_HPC/LabScripts/cluster_scripts/pybin/DGESeqSimuation/sam_parser.py /dev/stdin testresults.txt

"""
import os, sys, csv
import gtf_reader as greader

class SAMInstance:
    """class that holds information about each SAM read"""
    def __init__(self, line = None):
        """default constructor"""
        self.read_name = None
        self.flag = None
        self.chromosome = None
        self.start = 0 # 1-based index starting at left end of read
        self.end = 0
        self.mapq = None
        self.cigar = None
        self.mate_name = None
        self.mate_position = None
        self.template_length = None
        self.read_sequence = None
        self.read_quality = None
        self.program_flags = None
        if line is not None:
            self.__parseSAMLine(line)
    def __parseSAMLine(self, line):
        """split SAM line and assign values to variables"""
        line = line.split('\t')
        self.read_name = line[0]
        self.flag = line[1]
        self.chromosome = line[2]
        self.start = int(line[3]) # 1-based index starting at left end of read
        self.end = int(line[3]) + 100
        ##^ need to test
        #self.mapq = line[4]
        self.cigar = line[5]
        self.mate_name = line[6]
        self.mate_position = line[7]
        #self.template_length = line[8]
        #self.read_sequence = line[9]
        #self.read_quality = line[10]
        #self.program_flags = line[11]
    def compareToGTF(self, transcript_list):
        """finds and counts positions that match to gene transcripts list"""
        #print('Comparing to list')
        #print('Transcript list is')
        #print(transcript_list)
        for key in transcript_list:
            transcript = transcript_list[key]
            print(transcript)
            if transcript.chromosome == self.chromosome:
                print('Chromosomes match!')
                if transcript.end == self.end:
                    transcript.expression_count += 1
                    transcript.expression_positions.extend(self.position)
                    print('Found match!')
                transcript_list[key] = transcript
        return transcript_list
def inputTranscriptList(gtf_filename):
    """reads existing transcript list or generates new list if needed from GTF file"""
    input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    old_dir = os.getcwd()
    os.chdir(input_directory)
    if not os.path.exists('transcript_list.csv'):
        greader.processGTF(input_directory, gtf_filename)
    else:
        print('\n######\n\nTranscript list already exists!')
        print('Delete old list if you wish to build a new transcript list.\n\n######\n')
    list_file = open('transcript_list.csv', 'rb')
    reader = csv.reader(list_file)
    transcript_list = dict(x for x in reader)
    print('Transcript list is')
    print(transcript_list)
    os.chdir(old_dir)
    return transcript_list

# START of script
# define command line argument input
if len(sys.argv) != 3:
    sys.stderr.write("script must be given 2 arguments: input and output filenames")
input_file = sys.argv[1] # when using from samtools view: samtools view filename.bam | sam_parser.py /dev/stdin output_filename
output_file = sys.argv[2]

transcript_list = inputTranscriptList('genes.gtf')
print('\n\ntranscript_list is')
print(transcript_list)

# SAM file IO
input = open(input_file,'r')
output = open(output_file, 'w')

# read SAM file up to limit and run comparisons to transcript list
readcount = 0
##readlimit = 100000
print('reading!')
for line in input:
    #readcount += 1
    #print('Reading line %d' % readcount)
    sam = SAMInstance(line)
    transcript_list = sam.compareToGTF(transcript_list) ## figure out how input transcript list
    ##if readcount == readlimit:
    ##    break
print('writing!')
writecount = 0
writelimit = 8
for key in transcript_list:
    writecount += 1
    print('Writing line %d' % writecount)
    transcript = transcript_list[key]
    #if transcript.count > 0:
    output.write("%s contains %s exons and %s counts\n" % (transcript.name, transcript.num_exons, transcript.count))
    #output.write('Instance name is %s\n' % transcript.name)
    #output.write('Number of exons is %s\n' % transcript.num_exons)
    #output.write('Expression number is %s\n' % transcript.count)
    if writecount == writelimit:
        break
input.close()
output.close()
print('Job is Finished!')