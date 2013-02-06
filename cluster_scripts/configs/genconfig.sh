#!/bin/bash
cp /etc/man.config .
LIST=`grep ^setBiotoolPaths ../modulefiles/EversonLabBiotools/1.0 | tr "\n" ";" | tr " " "," | tr ";" " "`
#echo $LIST
PREFIX="/UCHC/HPC/Everson_HPC/"
MANSUFFIX="/share/man"
BINSUFFIX="/bin"
function doMAN {
if [ "${10}" -ne "0" ] 
then
	#echo "$2 ${10}"
	echo "MANPATH $PREFIX$2$MANSUFFIX" >> ./man.config
	if [ "$3" -ne "0" ]
	then
		echo "MANPATH_MAP $PREFIX$2$BINSUFFIX $PREFIX$2$MANSUFFIX" >> ./man.config
	fi
	#MANPATH_MAP     /bin                    /usr/share/man
fi
}

for f in $LIST
do
	MAN_INPUT=$(echo $f | tr "," " ")
	doMAN $MAN_INPUT
done