"""
sam_parser.py script
version 2013.08.02

@author: Bing
takes input from gene list file and sequence alignment map file and compares sequence reads to calculated stable regions of transcripts

run location: ssh mgooch@sig2-glx.cam.uchc.edu
sample command: samtools view /UCHC/Everson/Projects/Bladder/Pt5/RNA/TSRNA091711TCBL5_TOPHAT/accepted_hits.bam | python /UCHC/HPC/Everson_HPC/LabScripts/cluster_scripts/pybin/DGESeqSimulation/sam_parser.py /dev/stdin Pt5_TC_results.txt 200

"""
import os, sys, pickle
import gtf_reader as greader

class SequenceRead:
    """class that holds information about each SAM read"""
    def __init__(self, line = None):
        """default constructor"""
        self.read_name = None
        self.flag = None
        self.chromosome = None
        self.start = 0 # 1-based index starting at left end of read
        self.end = 0
        '''
        self.mapq = None
        self.cigar = None
        self.mate_name = None
        self.mate_position = None
        self.template_length = None
        self.read_sequence = None
        self.read_quality = None
        self.program_flags = None
        '''
        if line is not None:
            self.__parseSAMLine(line)
    def __parseSAMLine(self, line):
        """split SAM line and assign values to variables"""
        line = line.split('\t')
        self.read_name = line[0]
        self.flag = line[1]
        #self.chromosome = int(line[2][3:]) # OLD LOGIC: read line 2 starting from the 3rd position
        self.chromosome = line[2]
        self.start = int(line[3]) # 1-based index starting at left end of read
        self.end = int(line[3]) + 100
        '''
        self.mapq = line[4]
        self.cigar = line[5]
        self.mate_name = line[6]
        self.mate_position = line[7]
        self.template_length = line[8]
        self.read_sequence = line[9]
        self.read_quality = line[10]
        self.program_flags = line[11]
        '''
    def compareToGTF(self, gtf_list, readcount):
        """finds and counts positions that match to gene transcripts list"""
        for key in gtf_list:
            transcript = gtf_list[key]
            if transcript.start < self.end and transcript.end > self.start:
                if transcript.chromosome == self.chromosome:
                    #transcript.read_names.append(self.read_name)
                    #transcript.read_quality.append(self.read_quality)
                    transcript.expression_count += 1
                    print('Found match on line %d' % readcount) #debugging
                    gtf_list[key] = transcript
        return gtf_list, readcount
def inputTranscriptList(gtf_filename, transcript_list_filename, simulation_length):
    """reads existing transcript list or generates new list if needed from GTF file"""
    input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    old_dir = os.getcwd()
    os.chdir(input_directory)
    if not os.path.exists(transcript_list_filename):
        print('Building new transcript list...')
        greader.processGTF(input_directory, gtf_filename, transcript_list_filename, simulation_length)
    else:
        print('\n######\n\nThe transcript list already exists and does not need to be created. You have just saved 3 minutes of your life! Delete the old list if you wish to build a new transcript list.\n\n######\n')
    list_file = open(transcript_list_filename, 'rb')
    print('Loading transcript list...')
    gtf_list = pickle.load(list_file)
    os.chdir(old_dir)
    return gtf_list
def processSAMFile(sam_filename, gtf_list):
    # SAM file IO
    input = open(sam_filename,'r')
    
    # read SAM file up to limit and run comparisons to transcript list
    readcount = 0
    readlimit = 500 # debugging
    print('Reading...')
    for line in input:
        readcount += 1
        print('Reading line %d' % readcount)
        read = SequenceRead(line)
        gtf_list, readcount = read.compareToGTF(gtf_list, readcount)
        if readcount == readlimit:
            break
    input.close()
    return gtf_list
def outputMatches(output_filename, gtf_list):
    print('Writing...')
    
    old_dir = os.getcwd()
    os.chdir(os.path.join(os.path.dirname(__file__), 'Output'))
    output = open(output_filename, 'w')
    output.write('Transcript Name\tNumber of Exons\tNumber of Expressions\tTranscript Number ID\n')
    rowscount = 1
    try:
        rowslimit = len(gtf_list)
        ##print('Output table has %r transcripts' % rowslimit)
    except IndexError:
        print('Cannot output an empty table')
    for key in gtf_list:
        #print('Writing line %d' % rowscount)
        transcript = gtf_list[key]
        if transcript.expression_count > 0:
            output.write('%s\t%d\t%d\t%d\n' % (transcript.name, transcript.num_exons, transcript.expression_count, transcript.num_id))
        if rowscount == rowslimit:
            break
        rowscount += 1
    output.close()
    os.chdir(old_dir)
    #book.close()

# START of script
# define command line argument input
if len(sys.argv) != 4:
    sys.stderr.write("\nScript must be given 3 arguments: input filename, output filename, and simulation sequence length")
input_file = sys.argv[1] # when using from samtools view: samtools view filename.bam | sam_parser.py /dev/stdin output_filename sim_sequence_length
output_file = sys.argv[2]
simulation_length = int(sys.argv[3])

print('\nStarting the script...')
gtf_list = inputTranscriptList('genes.gtf', output_file[:-11] + 'simlength' + simulation_length + '_transcripts.csv', simulation_length)
gtf_list = processSAMFile(input_file, gtf_list)
outputMatches(output_file, gtf_list)
print('Job is Finished!')