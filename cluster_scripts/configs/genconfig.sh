#!/bin/bash
cp /etc/man.config .
LIST=`grep ^setBiotoolPaths ../modulefiles/EversonLabBiotools/1.0 | tr "\n" ";" | tr " " "," | tr ";" " "`
#echo $LIST

function doMAN {
if [ "${10}" -ne "0" ] 
then
	echo "$2 ${10}"
fi
}

for f in $LIST
do
	MAN_INPUT=$(echo $f | tr "," " ")
	doMAN $MAN_INPUT
done