#!/usr/bin/python
import subprocess
process = subprocess.Popen(['/usr/bin/yum','deplist','tcl'],shell=False,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
(process_stdout,Process_stderr) = process.communicate()

print process_stdout
print '\n'

print Process_stderr
print '\n'
