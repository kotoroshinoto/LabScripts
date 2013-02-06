#!/bin/bash
cp /etc/man.config .
LIST=`grep ^setBiotoolPaths ../modulefiles/EversonLabBiotools/1.0 | tr "\n" ";" | tr " " "," | tr ";" " "`
#echo $LIST

function doMAN {
	echo "$2 $10"
}

for f in $LIST
do
	MAN_INPUT=$(echo $f | tr "," " ")
	doMAN $MAN_INPUT
done