#methods.py
#version 2013.06.07
#group of methods that can be called by the main script

#Takes data from file and makes a table
def importTable(aInputFileName, aDirectory):
	import os
	
	#Set directory
	old_dir = os.getcwd()
	os.chdir(aDirectory)
	
	#Read data from input file and place in table
	f = open(aInputFileName, 'r')
	#BACKUP f = open('test.txt', 'r')
	f.readline() #reads and ignores the first line
	doc = f.read()
	table = [s.strip().split('\t') for s in doc.splitlines()]
	
	'''
	#Error check
		print '\nError Check 1'
		print 'The table is'
		print table
	'''

	#Find table size
	rows = len(table)
	print 'There are %r reads' % rows
	cols = len(table[0])
	print 'There are %r categories' % cols #cols should = 69

	'''
	#Error Check
		print '\nError Check 2'
		print 'Column 14 is'
		for x in range(0,rows):
			print table[x][15]
	'''
	return table

#Writes the table to a text file
def outputTable(anOutPutFileName, aTable):
	try:
		cols = len(aTable[0])
	except IndexError:
		print 'Cannot output empty table'
	
	#Write table into output file
	output = open(anOutPutFileName, 'w')
	#BACKUP output = open('output_keeps.txt', 'w')
	output.truncate()
	rows_keeps = len(aTable)
	print 'The result is %r rows' % rows_keeps
	for x in range(0, rows_keeps):
		for y in range(0, cols):
			#DEBUG print table[x][y]
			output.write(aTable[x][y]+'\t')
		output.write('\n')
	output.close()

#Makes new table with positions with KEEP
def saveKeeps(aTable):
	rows = len(aTable)
	table_keeps = []
	table_keeps.append(aTable[0]) #keep the categories
	for x in range (0, rows):
		#DEBUG print '\n table_keeps1 is %r' % table_keeps
		if aTable[x][68] == 'KEEP': #look only at column 69, which is KEEP or REJECT
			table_keeps.append(aTable[x])
	return table_keeps

#Makes new table with positions with REJECT
def saveRejects(aTable):
	rows = len(aTable)
	table_rejects = []
	table_rejects.append(aTable[0]) #keep the categories
	for x in range (0, rows):
		if aTable[x][68] == 'REJECT': #look only at column 69, which is KEEP or REJECT
			table_rejects.append(aTable[x])
	return table_rejects

#Compares position of two tables
def compareTables(first_table, second_table):
	rows_first_table = len(first_table)
	rows_second_table = len(second_table)
	print 'Comparing %r to %r rows' % (rows_first_table, rows_second_table)
	same_first_table = []
	same_second_table = []
	diff_first_table = []
	diff_first_table.append(first_table[0]) #keep the categories
	diff_second_table = []
	diff_second_table.append(second_table[0]) #keep the categories
	hash_table_first = {} #used to avoid writing the same rows repeatedly in table
	hash_table_first[first_table[0][1]] = first_table[0]
	hash_table_second = {}
	hash_table_second[second_table[0][1]] = second_table[0]
	for x in range(0, rows_first_table-1):
		for y in range(0, rows_second_table-1):
			#print y
			if first_table[x][1] == second_table[y][1]: #if a match
				same_first_table.append(first_table[x])
				same_second_table.append(second_table[y])
			else: #if not a match
				in_first_hash_table = first_table[x][1] in hash_table_first
				if in_first_hash_table is False:
					diff_first_table.append(first_table[x])
					hash_table_first[first_table[x][1]] = first_table[x]
				
				in_second_hash_table = second_table[y][1] in hash_table_second
				if in_second_hash_table is False:
					diff_second_table.append(second_table[y])
					hash_table_second[second_table[y][1]] = second_table[y]
	compact_result = [same_first_table, same_second_table, diff_first_table, diff_second_table]
	return compact_result

#End