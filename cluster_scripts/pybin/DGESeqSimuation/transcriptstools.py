"""
transcriptstools.py module
Version 2013.07.22

@author: Bing

"""
class Transcript:
    """object that holds information for each exon"""
    def __init__(self):
        self.confirmation = None
        self.name = None
        self.chromosome = None
        self.direction = None
        self.start = []
        self.end = []
        self.num_exons = 0
        self.threeprimeloc = None
        self.count = 0
        self.expression_positions = [] # positions in BAM file
    def setGeneEnd(self):
        """determines 3' end of entire gene based on read direction and ends of individual exons"""
        self.end.sort()
        if self.direction == '+':
            last_element = self.end[len(self.end) - 1]
            self.threeprimeloc = last_element
        elif self.direction == '-':
            first_element = self.end[0]
            self.threeprimeloc = first_element
def buildList(transcript, transcript_list):
    """adds transcripts to hash table with no duplicates"""
    in_list = transcript.name in transcript_list
    if in_list is False:
        transcript.num_exons += 1
        transcript_list[transcript.name] = transcript
        ##print('Added %s to transcript list' % transcript.name)
    else:
        transcript_stored = transcript_list[transcript.name]
        transcript_stored.num_exons += 1
        transcript_stored.start.extend(transcript.start)
        transcript_stored.end.extend(transcript.end)
        ##transcript_stored.end.sort()
        transcript_list[transcript.name] = transcript_stored
    return transcript_list
'''
def printList(transcript_list):
    """prints gene expression level for each gene in transcript list"""
    for key in transcript_list:
        instance = transcript_list[key]
        print('%s contains %s exons and ends at %s on %s' % (instance.name, instance.num_exons, instance.threeprimeloc, instance.chromosome))
'''