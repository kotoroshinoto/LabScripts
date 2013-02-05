#!/bin/bash
function linkfiles {
	DEST=$1
	shift
	for f in $@ 
	do
		echo "ln -f $f $DEST"
		ln -f $f $DEST
	done
}
#currently deploys "current pipeline"
chmod +x ./current_pipeline/*.sh 
FILES=`ls ./current_pipeline/*.sh`
FILES=$(echo $FILES | tr "\n" " ")
linkfiles $1 $FILES