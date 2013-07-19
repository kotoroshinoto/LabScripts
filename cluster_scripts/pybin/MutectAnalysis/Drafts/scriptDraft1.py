#script.py
#version 2013.06.06

'''
Options
	#Type in cmd.exe
	C:\\Python27\python C:\\Users\Bing\Videos\script.py
	
	#Use in linux
	/home/bing/Documents
	
	#Use in windows
	C:\\Users\Bing\Videos
	
'''
import methodslist as ml

#Import text to tables
#table1 = ml.importTable('mutect_call_stats.downsample.NC_TC.txt', 'C:\\Users\Bing\Videos')
#table2 = ml.importTable('mutect_call_stats.downsample.NF_TF.txt', 'C:\\Users\Bing\Videos')
table1 = ml.importTable('mutect_call_stats.purity.NC_TC.txt', 'C:\\Users\Bing\Videos')
table2 = ml.importTable('mutect_call_stats.purity.NF_TF.txt', 'C:\\Users\Bing\Videos')

#Save rows with detected mutations
keeps1 = ml.saveByValue(table1, 'judgement', 'KEEP')
#keeps1 = ml.saveKeeps(table1)
keeps2 = ml.saveKeeps(table2)

#Find mutated rows with that are matched and unmatched
total_comparison = ml.compareTables(keeps1, keeps2)
'''
0 is same_first_table
1 is same_second_table
2 is diff_first_table
3 is diff_second_table

'''
matched_keeps1 = total_comparison[0]
matched_keeps2 = total_comparison[1]
unmatched_keeps1 = total_comparison[2] ##
unmatched_keeps2 = total_comparison[3] ##

#Save rows with no detected mutations
rejects1 = ml.saveRejects(table1)
rejects2 = ml.saveRejects(table2)

#Compare unmatched KEEP rows of one table to REJECT rows of other table
total_compare_reject2_unmatched1 = ml.compareTables(unmatched_keeps1, rejects2)
matched_reject2_unmatched1 = total_compare_reject2_unmatched1[1] #1 is the second table

total_compare_reject1_unmatched2 = ml.compareTables(unmatched_keeps2, rejects1)
matched_reject1_unmatched2 = total_compare_reject1_unmatched2[1]
'''
#Debug
	ml.outputTable('rejects_NC_TC.txt', rejects1)
	ml.outputTable('rejects_NF_TF.txt', rejects2)

	ml.outputTable('unmatched_NC_TC.txt', unmatched_keeps1)
	ml.outputTable('unmatched_NF_TF.txt', unmatched_keeps2)
	
'''
#Select only certain categories
keeps1 = ml.selectCategories(keeps1)
keeps2 = ml.selectCategories(keeps2)
matched_reject1_unmatched2 = ml.selectCategories(matched_reject1_unmatched2)
matched_reject2_unmatched1 = ml.selectCategories(matched_reject2_unmatched1)

#Write tables to text files
ml.outputTable('output_keeps.NC_TC.txt', keeps1)
ml.outputTable('output_keeps.NF_TF.txt', keeps2)
ml.outputTable('output_reject of unmatched.NC_TC.txt', matched_reject1_unmatched2)
ml.outputTable('output_reject of unmatched.NF_TF.txt', matched_reject2_unmatched1)

print 'Finished'