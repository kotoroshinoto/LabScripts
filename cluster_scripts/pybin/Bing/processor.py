"""
processor.py
version 2013.06.21

"""
def processMutations(first_file, second_file , input_directory, output_file, output_directory, lines_skip):
	import methodslist as ml
	import xlwt
	import os
	
	# Set directory
	old_dir = os.getcwd()
	os.chdir(output_directory)
	
	print '\nStarting at %r' % input_directory
	
	# Import text to tables
	table1 = ml.importTable(first_file, input_directory, lines_skip)
	table2 = ml.importTable(second_file, input_directory, lines_skip)

	# Save rows with detected mutations
	keeps1 = ml.saveByValue(table1, 'judgement', 'KEEP')
	keeps2 = ml.saveByValue(table2, 'judgement', 'KEEP')

	# Find mutated rows with that are matched and unmatched
	total_comparison = ml.compareTables(keeps1, keeps2)
	'''
	0 is same_first_table
	1 is same_second_table
	2 is diff_first_table
	3 is diff_second_table

	'''
	matched_keeps1 = total_comparison[0]
	matched_keeps2 = total_comparison[1]
	unmatched_keeps1 = total_comparison[2]
	unmatched_keeps2 = total_comparison[3]
	
	# Save rows with no detected mutations
	rejects1 = ml.saveByValue(table1, 'judgement', 'REJECT')
	rejects2 = ml.saveByValue(table2, 'judgement', 'REJECT')

	# Compare unmatched KEEP rows of one table to REJECT rows of other table
	total_compare_reject2_unmatched1 = ml.compareTables(unmatched_keeps1, rejects2)
	matched_reject2_unmatched1 = total_compare_reject2_unmatched1[1] # 1 is the second column
	total_compare_reject1_unmatched2 = ml.compareTables(unmatched_keeps2, rejects1)
	matched_reject1_unmatched2 = total_compare_reject1_unmatched2[1]

	# Select only certain categories
	keeps1 = ml.saveByCategory(keeps1)
	keeps2 = ml.saveByCategory(keeps2)
	matched_reject2_unmatched1 = ml.saveByCategory(matched_reject2_unmatched1)
	matched_reject1_unmatched2 = ml.saveByCategory(matched_reject1_unmatched2)
	
	# Calculate concordance between NC TC and NF TF
	concordance_table = ml.calcCondordance(unmatched_keeps1, unmatched_keeps2, matched_keeps1)
	
	# Write tables to text files
	book = xlwt.Workbook()
	
	ml.outputTable(book, concordance_table, 'Concordance Summary', output_directory)
	ml.outputTable(book, keeps1, 'NC TC KEEP', output_directory)
	ml.outputTable(book, keeps2, 'NF TF KEEP', output_directory)
	ml.outputTable(book, matched_reject2_unmatched1, 'NF TF Matched REJECTS', output_directory)
	ml.outputTable(book, matched_reject1_unmatched2, 'NC TC Matched REJECTS', output_directory)
	
	book.save(output_file)
	os.chdir(old_dir)
	print('Finished')
	
def processGeneCalls(first_file, second_file , input_directory, output_file, output_directory, lines_skip):
	import methodslist as ml
	import xlwt
	import os
	
	# Set directory
	old_dir = os.getcwd()
	os.chdir(output_directory)
	
	print '\nStarting at %r' % input_directory

	# Import text to tables
	table1 = ml.importTable(first_file, input_directory, lines_skip)
	table2 = ml.importTable(second_file, input_directory, lines_skip)

	# Find mutated rows with that are matched and unmatched
	total_comparison = ml.compareTables(table1, table2)
	matched1 = total_comparison[0]
	matched2 = total_comparison[1]
	unmatched1 = total_comparison[2]
	unmatched2 = total_comparison[3]
	
	'''
	#Select only certain categories
	keeps1 = ml.saveByCategory(keeps1)
	keeps2 = ml.saveByCategory(keeps2)
	matched_reject2_unmatched1 = ml.saveByCategory(matched_reject2_unmatched1)
	matched_reject1_unmatched2 = ml.saveByCategory(matched_reject1_unmatched2)
	'''
	
	# Calculate condordance
	condordance_table = ml.calcCondordance(unmatched1, unmatched2, matched1)
	
	# Write tables to text files
	book = xlwt.Workbook()
	
	ml.outputTable(book, condordance_table, 'Concordance Summary', output_directory)
	ml.outputTable(book, table1, 'NC TC Input', output_directory)
	ml.outputTable(book, table2, 'NF TF Input', output_directory)
	ml.outputTable(book, matched1, 'NC TC Matches', output_directory)
	ml.outputTable(book, matched2, 'NF TF Matches', output_directory)
	book.save(output_file)
	os.chdir(old_dir)
	
	print 'Finished'
	
def processNucleotides(first_file, second_file , input_directory, output_file, output_directory, lines_skip):
	import methodslist as ml
	import xlwt
	import os
	
	# Set directory
	old_dir = os.getcwd()
	os.chdir(output_directory)
	print '\nStarting at %r' % input_directory

	# Import text to tables
	table1 = ml.importTable(first_file, input_directory, lines_skip)
	table2 = ml.importTable(second_file, input_directory, lines_skip)
	
	# Compare Nucleotide Changes 1st Sheet
	table0 = ['Change',
				'A to T', 'A to C', 'A to G',
				'T to A', 'T to C', 'T to G',
				'C to A', 'C to T', 'C to G',
				'G to A', 'G to T', 'G to C']

	rows1 = len(table1)
	print('Comparing %r positions' % rows1)
	a_to_t = 0
	a_to_g = 0
	a_to_c = 0
	t_to_a = 0
	t_to_c = 0
	t_to_g = 0
	c_to_a = 0
	c_to_t = 0
	c_to_g = 0
	g_to_a = 0
	g_to_t = 0
	g_to_c = 0
	
	for x in range (1, rows1):
		if table1[x][3] == 'A':
			if table1[x][4] == 'T':
				a_to_t += 1
			elif table1[x][4] == 'C':
				a_to_c += 1
			elif table1[x][4] == 'G':
				a_to_g += 1
		elif table1[x][3] == 'T':
			if table1[x][4] == 'A':
				t_to_a += 1
			elif table1[x][4] == 'C':
				t_to_c += 1
			elif table1[x][4] == 'G':
				t_to_g += 1
		elif table1[x][3] == 'C':
			if table1[x][4] == 'A':
				c_to_a += 1
			elif table1[x][4] == 'T':
				c_to_t += 1
			elif table1[x][4] == 'G':
				c_to_g += 1
		elif table1[x][3] == 'G':
			if table1[x][4] == 'A':
				g_to_a += 1
			elif table1[x][4] == 'T':
				g_to_t += 1
			elif table1[x][4] == 'C':
				g_to_c += 1
	
	a_to_t = a_to_t/(rows1 - 1.0)
	a_to_g = a_to_g/(rows1 - 1.0)
	a_to_c = a_to_c/(rows1 - 1.0)
	t_to_a = t_to_a/(rows1 - 1.0)
	t_to_c = t_to_c/(rows1 - 1.0)
	t_to_g = t_to_g/(rows1 - 1.0)
	c_to_a = c_to_a/(rows1 - 1.0)
	c_to_t = c_to_t/(rows1 - 1.0)
	c_to_g = c_to_g/(rows1 - 1.0)
	g_to_a = g_to_a/(rows1 - 1.0)
	g_to_t = g_to_t/(rows1 - 1.0)
	g_to_c = g_to_c/(rows1 - 1.0)
	
	table1 = ['NC TC',
				a_to_t, a_to_c, a_to_g,
				t_to_a, t_to_c, t_to_g,
				c_to_a, c_to_t, c_to_g,
				g_to_a, g_to_t, g_to_c]

	rows2 = len(table2)
	print('Comparing %r positions' % rows2)
	a_to_t = 0
	a_to_g = 0
	a_to_c = 0
	t_to_a = 0
	t_to_c = 0
	t_to_g = 0
	c_to_a = 0
	c_to_t = 0
	c_to_g = 0
	g_to_a = 0
	g_to_t = 0
	g_to_c = 0
	
	for x in range (1, rows2):
		if table2[x][3] == 'A':
			if table2[x][4] == 'T':
				a_to_t += 1
			elif table2[x][4] == 'C':
				a_to_c += 1
			elif table2[x][4] == 'G':
				a_to_g += 1
		elif table2[x][3] == 'T':
			if table2[x][4] == 'A':
				t_to_a += 1
			elif table2[x][4] == 'C':
				t_to_c += 1
			elif table2[x][4] == 'G':
				t_to_g += 1
		elif table2[x][3] == 'C':
			if table2[x][4] == 'A':
				c_to_a += 1
			elif table2[x][4] == 'T':
				c_to_t += 1
			elif table2[x][4] == 'G':
				c_to_g += 1
		elif table2[x][3] == 'G':
			if table2[x][4] == 'A':
				g_to_a += 1
			elif table2[x][4] == 'T':
				g_to_t += 1
			elif table2[x][4] == 'C':
				g_to_c += 1
	
	a_to_t = a_to_t/(rows1 - 1.0)
	a_to_g = a_to_g/(rows1 - 1.0)
	a_to_c = a_to_c/(rows1 - 1.0)
	t_to_a = t_to_a/(rows1 - 1.0)
	t_to_c = t_to_c/(rows1 - 1.0)
	t_to_g = t_to_g/(rows1 - 1.0)
	c_to_a = c_to_a/(rows1 - 1.0)
	c_to_t = c_to_t/(rows1 - 1.0)
	c_to_g = c_to_g/(rows1 - 1.0)
	g_to_a = g_to_a/(rows1 - 1.0)
	g_to_t = g_to_t/(rows1 - 1.0)
	g_to_c = g_to_c/(rows1 - 1.0)
	
	table2 = ['NF TF',
				a_to_t, a_to_c, a_to_g,
				t_to_a, t_to_c, t_to_g,
				c_to_a, c_to_t, c_to_g,
				g_to_a, g_to_t, g_to_c]
	
	'''
	table2 = []
	table2.append(a_to_t)
	table2.append(a_to_c)
	table2.append(a_to_g)

	table2.append(t_to_a)
	table2.append(t_to_c)
	table2.append(t_to_g)

	table2.append(c_to_a)
	table2.append(c_to_t)
	table2.append(c_to_g)

	table2.append(g_to_a)
	table2.append(g_to_t)
	table2.append(g_to_c)
	
	table2 = []
	table2.append(['A to T', a_to_t])
	table2.append(['A to C', a_to_c])
	table2.append(['A to G', a_to_g])

	table2.append(['T to A', t_to_a])
	table2.append(['T to C', t_to_c])
	table2.append(['T to G', t_to_g])

	table2.append(['C to A', c_to_a])
	table2.append(['C to T', c_to_t])
	table2.append(['C to G', c_to_g])

	table2.append(['G to A', g_to_a])
	table2.append(['G to T', g_to_t])
	table2.append(['G to C', g_to_c])
	'''
	
	# Output Table
	book = xlwt.Workbook()
	sheet = book.add_sheet('Nucleotide Changes')
	
	rows = len(table1)
	print 'Output table has %r positions' % rows
	for x in range(0, rows):
		sheet.write(x, 0, table0[x])
		sheet.write(x, 1, table1[x])
		sheet.write(x, 2, table2[x])
	book.save(output_file)
	
	os.chdir(old_dir)
	print 'Finished'