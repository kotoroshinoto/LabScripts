"""
transcriptstools.py module
Version 2013.08.02

@author: Bing

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
        if line[check_format_index] == 'transcript_id':
            ##exon.correct_input = True
            self.name = line[check_format_index + 1]
            if line[0].find('chr') != -1:
                self.chromosome = (line[0])[3:]
            else:
                self.chromosome = line[0]
            self.direction = line[6]
            self.start = line[3] # start is always left side of exon whether forward or reverse
            self.end = line[4]
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
        self.exon_starts.sort()
        self.exon_ends.sort()
        if self.direction == '+':
            exon_index = -1 # counts backward from the right most exon
            last_element = self.exon_ends[exon_index]
            self.end = int(last_element)
            self.start = self.end - simulation_length
            while self.start < int(self.exon_starts[exon_index]): # account for intron area if end exon is shorter than desired read length
                print('Compensating for introns...')
                try:
                    intron_area = int(self.exon_ends[exon_index - 1]) - int(self.exon_starts[exon_index])
                except:
                    print('Simulation sequence length is longer than transcript length')
                    print('Compensation is skipped')
                    break
                print('Compensated for %d introns' % (1 - exon_index))
                intron_area = 10
                self.start = self.start - intron_area
                exon_index -= 1 # check next exon
        elif self.direction == '-':
            exon_index = 0
            first_element = self.exon_starts[exon_index]
            self.start = int(first_element)
            self.end = self.start + simulation_length
            while self.end > self.exon_ends[exon_index]:
                try:
                    intron_area = int(self.exon_ends[exon_index + 1]) - int(self.exon_starts[exon_index])
                except:
                    print('Simulation sequence length is longer than transcript length')
                    print('Script will continue...')
                    break
                self.end = self.end + intron_area
                exon_index += 1 # check next exon
        if self.start < 0:
            print('Length Error: gene starts at negative position')
def buildList(exon, transcript_list, transcript_count):
    """adds transcripts to hash table with no duplicates"""
    in_list = exon.name in transcript_list
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
        transcript_list[transcript.name] = transcript
        ##print('Added new %s to transcript list' % exon.name)
    else:
        transcript_stored = transcript_list[exon.name]
        transcript_stored.num_exons += 1
        transcript_stored.exon_starts.append(exon.start)
        transcript_stored.exon_ends.append(exon.end)
        ##transcript_stored.end.sort()
        transcript_list[exon.name] = transcript_stored
    return transcript_list, transcript_count