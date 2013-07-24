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
        self.start = []
        self.end = []
        if line is not None:
            self.parseGTFLine(line)
    def __parseGTFLine(self, line):
        """assign values in line as exon attributes"""
        check_format_index = 10
        if line[check_format_index] == 'transcript_id':
            ##exon.correct_input = True
            self.name = line[check_format_index + 1]
            self.chromosome = line[0]
            self.direction = line[6]
            if self.direction == '+':
                self.start.append(line[3])
                self.end.append(line[4])
            elif self.direction == '-':
                self.start.append(line[4])
                self.end.append(line[3])
            else:
                raise SyntaxError('Data incorrectly states whether exon is foward/reverse read\n')
        else:
            raise IOError('transcript_id is not in the correct column\n')
class Transcript:
    """object that holds information for each transcript"""
    def __init__(self):
        self.name = None
        self.chromosome = None
        ##self.direction = None
        self.start = []
        self.end = []
        self.num_exons = 0
        self.expression_count = 0
        self.expression_positions = [] # positions in BAM fil 
    def setGeneEnd(self):
        """determines 3' end of entire gene based on read direction and ends of individual exons"""
        self.end.sort()
        if self.direction == '+':
            last_element = self.end[len(self.end) - 1]
            self.end = last_element
        elif self.direction == '-':
            first_element = self.end[0]
            self.end = first_element
        self.start = self.end - 300
        if self.start < 0:
            print('Length Error: gene starts at negative position')
def buildList(exon, transcript_list):
    """adds transcripts to hash table with no duplicates"""
    in_list = exon.name in transcript_list
    if in_list is False:
        transcript = Transcript()
        transcript.name = exon.name
        transcript.chromosome = exon.chromosome
        transcript.num_exons += 1
        transcript_list[transcript.name] = transcript
        print('Added new %s to transcript list' % exon.name)
    else:
        transcript_stored = transcript_list[exon.name]
        transcript_stored.num_exons += 1
        transcript_stored.start.extend(int(exon.start))
        transcript_stored.end.extend(int(exon.end))
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