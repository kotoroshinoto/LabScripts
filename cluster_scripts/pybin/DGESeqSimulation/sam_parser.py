"""
sam_parser.py script
version 2013.08.08

@author: Bing
takes input from gene list file and sequence alignment map file and compares sequence reads to calculated stable regions of transcripts

run location: ssh mgooch@sig2-glx.cam.uchc.edu
new: generates BAM file with sequences from stable transcript regions
"""
import os, sys, pickle, datetime
import pysam

is_debug = False
is_capture_sequence = False

def inputTranscriptList(transcriptlist_filename):
    """reads transcript list file"""
    print('Loading transcript list...')
    try:
        input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    except:
        os.mkdir(os.path.join(os.path.dirname(__file__), 'Input'))
        print('Error: transcript list file and input folder do not exist. Please place transcript file into newly generated input folder.')
    old_dir = os.getcwd()
    os.chdir(input_directory)
    try:
        list_file = open(transcriptlist_filename, 'rb')
    except IOError:
        print('Error: failed to load transcript list file')
    transcript_list = pickle.load(list_file)
    os.chdir(old_dir)
    return transcript_list
def processSAMFile(input_bam_filename, transcript_list, output_bam_filename=None):
    """reads sequences from SAM file and calculate gene expression level by comparing to transcript list"""
    # SAM file IO
    print('Reading...')
    seqinput = pysam.Samfile(input_bam_filename) # automatically checks for 'rb' and then 'r' modes
    if is_capture_sequence:
        seqoutput = pysam.Samfile(output_bam_filename, 'wb', template=seqinput)
        print('Copying specific sequences while reading...')
        
    # read SAM file and run comparisons to transcript list
    readcount = 0
    if is_debug:
        readlimit = 10000
    print('Processed 0 reads @ %s' % datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    for seqread in seqinput.fetch(until_eof=True):
        readcount += 1
        transcripts_at_chromosome = transcript_list.get(seqinput.getrname(seqread.tid))
        if transcripts_at_chromosome == None:
            continue
        for transcript in transcripts_at_chromosome:
            '''
            TODO:
            could possibly iterate over transcripts and use 
            pysam.Samfile.count(reference="chr#',start=#,end=#) > 0
            
            or
            
            could potentially fetch once per reference sequence (chromosome) 
            and only compare reads agaisnt transcripts from same chromosome
            would only benefit if pysam reads entire samfile ahead of time 
            or on first fetch (and then retains it for later use)
            '''
            seqread_start = seqread.pos
            seqread_end = seqread.pos + (seqread.qend - seqread.qstart)
            if transcript.start <= seqread_start and transcript.end >= seqread_end:
                transcript.expression_count += 1
                if is_capture_sequence:
                    seqoutput.write(seqread)
                if is_debug:
                    print('Found match on line %d for %r' % (readcount, transcript.name))
        if readcount % 100000 == 0:
            print('Processed %d reads @ %s' % (readcount,datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
        if is_debug:
            if readcount == readlimit:
                break
    seqinput.close()
    if is_capture_sequence:
        seqoutput.close()
def outputMatches(output_filename, transcript_list):
    """writes transcript lists with expression level counts to file"""
    print('Writing...')
    old_dir = os.getcwd()
    output_dir = os.path.join(os.path.dirname(__file__), 'Output')
    if not os.path.exists(output_dir):
        os.mkdir(output_dir)
    os.chdir(output_dir)
    output = open(output_filename, 'w')
    output.write('Transcript Name\tNumber of Exons\tNumber of Expressions\tTranscript Number ID\n')
    for chromosome in transcript_list:
        transcripts_at_chromosome = transcript_list[chromosome]
        for transcript in transcripts_at_chromosome:
            if transcript.expression_count > 0:
                output_string = '%s\t%d\t%d\t%d' % (transcript.name, transcript.num_exons, transcript.expression_count, transcript.num_id)
                if is_debug:
                    print(output_string)
                output.write(output_string + '\n')
    output.close()
    os.chdir(old_dir)

# START OF SCRIPT
# define argument input
if len(sys.argv) != 4:
    sys.stderr.write('\nScript must be given 3 arguments: sam filename, transcript list filename, and comparison output filename')
sam_filename = sys.argv[1]
transcriptlist_filename = sys.argv[2]
output_filename = sys.argv[3]

print('\nStarting the script...')
transcript_list = inputTranscriptList(transcriptlist_filename)
processSAMFile(sam_filename, transcript_list)
outputMatches(output_filename, transcript_list)
print('Job is Finished!')