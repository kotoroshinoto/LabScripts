#!/bin/bash
#currently deploys "current pipeline"
chmod +x ./current_pipeline/*.sh 
FILES=`ls ./current_pipeline/*.sh`
echo "LINKING FILES: $FILES to $1"
for f in FILES 
do
echo "ln -f $f $1"
#ln -f $f $1
done