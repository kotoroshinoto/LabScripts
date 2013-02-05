#!/bin/bash
#currently deploys "current pipeline"
chmod +x ./current_pipeline/*.sh 
FILES=`ls ./current_pipeline/*.sh`
FILES=$(echo $FILES | tr "\n" " ")

function linkfiles {
	for f in $@ 
	do
		echo "ln -f $f $1"
	#ln -f $f $1
	done
}