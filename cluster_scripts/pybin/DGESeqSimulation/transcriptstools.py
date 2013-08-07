"""
transcriptstools.py module
version 2013.08.05

@author: Bing
methods and objects that store and manipulate exon and transcript information

"""
class Exon:
    """object that holds information for each exon"""
    def __init__(self, line = None):
        ##self.correct_input = None
        self.name = None
        self.chromosome = None
        self.direction = None
        self.start = None
        self.end = None
        if line is not None:
            self.__parseGTFLine(line)
    def __parseGTFLine(self, line):
        """assign values in line as exon attributes"""
        check_format_index = 10
        if line[2] == 'exon':
            if line[check_format_index] == 'transcript_id':
                ##exon.correct_input = True
                self.name = line[check_format_index + 1]
                self.chromosome = line[0]
                self.direction = line[6]
                self.start = int(line[3]) - 1 # start is always left side of exon whether forward or reverse
                self.end = int(line[4]) - 1
            else:
                raise IOError('transcript_id is not in the correct column\n')
class Transcript:
    """object that holds information for each transcript"""
    def __init__(self):
        self.name = None
        self.num_id = 0 # used for easier plotting
        self.chromosome = None
        self.direction = None
        self.exon_starts = []
        self.exon_ends = []
        self.start = 0
        self.end = 0
        self.num_exons = 0
        self.expression_count = 0
        #self.expression_positions = [] # positions in BAM file 
        self.read_names = []
        self.read_quality = []
    def setGeneEnd(self, simulation_length):
        """determines stable segment of entire transcript based on read direction and individual exons"""
        try:
            self.exon_starts.sort()
            self.exon_ends.sort()
        except:
            if self.name == None:
                pass
        if self.direction == '+':
            exon_index = -1 # counts backward from the right most exon
            last_element = self.exon_ends[exon_index]
            self.end = last_element
            self.start = self.end - simulation_length
            while self.start < self.exon_starts[exon_index]: # account for intron area if end exon is shorter than desired read length
                #print('Compensating for introns...')
                try:
                    intron_area = self.exon_ends[exon_index - 1] - self.exon_starts[exon_index]
                except:
                    #print('Simulation sequence length is longer than transcript length')
                    #print('Compensation is skipped')
                    break
                #print('Compensated for %d intronic regions' % (1 - exon_index))
                self.start = self.start - intron_area
                exon_index -= 1 # check next exon
        elif self.direction == '-':
            exon_index = 0
            first_element = self.exon_starts[exon_index]
            self.start = first_element
            self.end = self.start + simulation_length
            while self.end > self.exon_ends[exon_index]:
                try:
                    intron_area = self.exon_ends[exon_index + 1] - self.exon_starts[exon_index]
                except:
                    #print('Simulation sequence length is longer than transcript length')
                    #print('Script will continue...')
                    break
                self.end = self.end + intron_area
                exon_index += 1 # check next exon
        if self.start < 0:
            print('Length Error: gene starts at negative position')
def buildTranscriptDictionary(exon, transcript_dict, transcript_count):
    """adds transcripts to hash table with no duplicates"""
    in_list = exon.name in transcript_dict
    if in_list is False:
        transcript = Transcript()
        transcript.name = exon.name
        transcript.num_id = transcript_count
        transcript_count += 1
        transcript.chromosome = exon.chromosome
        transcript.direction = exon.direction
        transcript.exon_starts.append(exon.start)
        transcript.exon_ends.append(exon.end)
        transcript.num_exons += 1
        transcript_dict[transcript.name] = transcript
        ##print('Added new %s to transcript list' % exon.name)
    else:
        transcript_stored = transcript_dict[exon.name]
        transcript_stored.num_exons += 1
        transcript_stored.exon_starts.append(exon.start)
        transcript_stored.exon_ends.append(exon.end)
        transcript_dict[exon.name] = transcript_stored
    return transcript_dict, transcript_count
def buildTranscriptList(transcript_dict):
    """adds transcripts to hash table with chromosome as key"""
    transcript_list = {}
    for key in transcript_dict:
        transcript = transcript_dict[key]
        in_list = transcript.chromosome in transcript_list
        if in_list is False:
            transcript_list[transcript.chromosome] = [transcript]
        else:
            transcripts_at_chromosome = transcript_list[transcript.chromosome]
            transcripts_at_chromosome.append(transcript)
            transcript_list[transcript.chromosome] = transcripts_at_chromosome
    return transcript_list