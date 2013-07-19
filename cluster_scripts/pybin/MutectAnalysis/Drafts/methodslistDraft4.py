#methods.py
#version 2013.06.07
#group of methods that can be called by the main script

#Takes data from file and makes a table
def importTable(input_file_name, a_directory):
	import os
	
	#Set directory
	old_dir = os.getcwd()
	os.chdir(a_directory)
	
	#Read data from input file and place in table
	f = open(input_file_name, 'r')
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
	print 'Input table has %r positions' % rows
	cols = len(table[0])
	#print 'Table has %r categories' % cols

	'''
	#Error Check
		print '\nError Check 2'
		print 'Column 14 is'
		for x in range(0,rows):
			print table[x][15]
	'''
	return table

#Writes the table to a text file
def outputTable(output_file_name, a_table):
	try:
		cols = len(a_table[0])
	except IndexError:
		print 'Cannot output an empty table'
	
	#Write table into output file
	output = open(output_file_name, 'w')
	output.truncate()
	rows_keeps = len(a_table)
	print 'Output table has %r positions' % rows_keeps
	for x in range(0, rows_keeps):
		for y in range(0, cols):
			#DEBUG print table[x][y]
			output.write(a_table[x][y]+'\t')
		output.write('\n')
	output.close()

#Saves rows based on a category value
def saveByValue(a_table, a_category, a_value):
	rows = len(a_table)
	cols = len(a_table[0])
	table_new = []
	table_new.append(a_table[0]) #keep the categories
	for x in range (0, cols):
		if a_table[0][x] == a_category: #find the category's col number
			category_col_num = x
	for x in range (0, rows):
		if a_table[x][category_col_num] == a_value: #compare value at col
			table_new.append(a_table[x])
	return table_new

#Makes new table with positions with KEEP
def saveKeeps(a_table):
	rows = len(a_table)
	table_keeps = []
	table_keeps.append(a_table[0]) #keep the categories
	for x in range (0, rows):
		#DEBUG print '\n table_keeps1 is %r' % table_keeps
		if a_table[x][68] == 'KEEP': #look only at column 69, which is KEEP or REJECT
			table_keeps.append(a_table[x])
	return table_keeps

#Makes new table with positions with REJECT
def saveRejects(a_table):
	rows = len(a_table)
	table_rejects = []
	table_rejects.append(a_table[0]) #keep the categories
	for x in range (0, rows):
		if a_table[x][68] == 'REJECT': #look only at column 69, which is KEEP or REJECT
			table_rejects.append(a_table[x])
	return table_rejects

#Compares position of two tables
def compareTables(first_table, second_table):
	rows_first_table = len(first_table)
	rows_second_table = len(second_table)
	print 'Comparing %r to %r positions' % (rows_first_table, rows_second_table)
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
	for x in range(0, rows_first_table):
		for y in range(0, rows_second_table):
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

#Keeps only certain categories
def selectCategories(a_table):
	rows = len(a_table)
	cols = len(a_table[0])
	new_table = []
	selected_cols = [0, 1, 2, 3, 4, 5, 6, 8, 9, 18, 19, 26, 28, 29, 36, 37, 38, 46, 47, 67, 68]
	for x in range(0, rows):
		new_row = []
		for y in selected_cols:
			new_row.append(a_table[x][y])
		new_table.append(new_row)
	return new_table

#End