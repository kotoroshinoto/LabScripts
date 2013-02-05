#!/usr/bin/python
import re, glob, os
import sys
import getopt
import shutil

def renamer(files, pattern, replacement):
	for pathname in glob.glob(files):
		#print ("path name:",pathname)
		basename= os.path.basename(pathname)
		#print ("base name:",basename)
		new_filename= re.sub(pattern, replacement, basename)
		#print ("new filename:",new_filename)
		if new_filename != basename:
			print ("renaming",pathname,"to",os.path.join(os.path.dirname(pathname), new_filename))
			os.rename(pathname,os.path.join(os.path.dirname(pathname),"rename_tmp", new_filename))
			derp=""

def read_name_file(fname,names):
	print ("opening",fname,"for list of rename labels")
	err=""
	buf=""
	f=""
	try:
		f=open(fname)
		try:
			# Read the entire POST log file into a buffer
			buf += f.read()
		except IOError:
			err += "The file could not be read."
		f.close()
	except IOError:
		err += "The file could not be opened."
	if(err != ""):
		print (err)
		return
	else:
		#parse buf
		lines=buf.split("\n")
		for line in lines:
			if(line != ""):
				tabs=line.split("\t")
				#print tabs
				names.append(tabs)
		#print lines

def main(argv=None):
	if argv is None:
		argv = sys.argv
#	print argv
#	print len(argv)
	if(len(argv) != 2):
		print ("usage: renamer.py [filename]")
		return
	names=[]
	read_name_file(argv[1],names)
	#print names
	if(os.path.exists("rename_tmp")):
		if(os.path.isdir("rename_tmp")):
			print ("tmp dir exists")
		else:
			print ("file exists with name of tmp dir")
			return
	else:
		os.mkdir("rename_tmp")
#sanity check
	for name1 in names:
		for name2 in names:
			if(name1[1] == name2[1] and not(name1[1] is name2[1])):
				print ("Attempting to rename more than one file to the same destination:",name1,",",name2)
				return
	for name in names:
		#print name
		files=name[0]+"*"
		pattern=r"^"+name[0]+"(.*)$"
		replacement=r""+name[1]+"\\1"
		#print files
		#print pattern
		#print replacement
		renamer(files, pattern, replacement)
	for pathname in glob.glob("rename_tmp/*"):
		shutil.move(pathname,".")
	os.rmdir("rename_tmp")

if __name__ == "__main__":
    sys.exit(main())

