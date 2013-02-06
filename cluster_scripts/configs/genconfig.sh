#!/bin/bash
cp /etc/man.config .
LIST=`grep ^setBiotoolPaths ../modulefiles/EversonLabBiotools/1.0 | tr "\n" ";" | tr " " "," | tr ";" " "`
#LIST=$(echo $LIST | tr " " ",")
#LIST=$(echo $LIST | tr "\n" " ")
echo $LIST

for f in $LIST
do
	echo $f
done