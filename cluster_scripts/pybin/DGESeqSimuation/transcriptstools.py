"""
transcriptstools.py module
Version 2013.07.24

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
            self.chromosome = line[0]
            self.direction = line[6]
            if self.direction == '+':
                self.start = line[3]
                self.end = line[4]
            elif self.direction == '-':
                self.start = line[4]
                self.end = line[3]
            else:
                raise SyntaxError('Data incorrectly states whether exon is forward/reverse read\n')
        else:
            raise IOError('transcript_id is not in the correct column\n')
class Transcript:
    """object that holds information for each transcript"""
    def __init__(self):
        self.name = None
        self.chromosome = None
        self.direction = None
        self.exon_starts = []
        self.exon_ends = []
        self.start = 0
        self.end = 0
        self.num_exons = 0
        self.expression_count = 0
        self.expression_positions = [] # positions in BAM file 
    def setGeneEnd(self):
        """determines 3' end of entire gene based on read direction and ends of individual exons"""
        self.exon_ends.sort()
        if self.direction == '+':
            print(self.exon_ends)
            print(self.exon_ends[-1])
            last_element = self.exon_ends[-1]
            self.end = int(last_element)
        elif self.direction == '-':
            first_element = self.exon_ends[0]
            self.end = int(first_element)
        self.start = self.end - 250
        if self.start < 0:
            print('Length Error: gene starts at negative position')
def buildList(exon, transcript_list):
    """adds transcripts to hash table with no duplicates"""
    in_list = exon.name in transcript_list
    if in_list is False:
        transcript = Transcript()
        transcript.name = exon.name
        transcript.chromosome = exon.chromosome
        transcript.direction = exon.direction
        transcript.num_exons += 1
        transcript_list[transcript.name] = transcript
        print('Added new %s to transcript list' % exon.name)
    else:
        transcript_stored = transcript_list[exon.name]
        transcript_stored.num_exons += 1
        transcript_stored.exon_starts.extend(exon.start)
        transcript_stored.exon_ends.extend(exon.end)
        ##transcript_stored.end.sort()
        transcript_list[exon.name] = transcript_stored
    return transcript_list
'''
def printList(transcript_list):
    """prints gene expression level for each gene in transcript list"""
    for key in transcript_list:
        instance = transcript_list[key]
        print('%s contains %s exons and ends at %s on %s' % (instance.name, instance.num_exons, instance.threeprimeloc, instance.chromosome))
'''