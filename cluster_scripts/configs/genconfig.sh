#!/bin/bash
cp /etc/man.config .
LIST=`grep ^setBiotoolPaths ../modulefiles/EversonLabBiotools/1.0 | tr "\n" ";"`
#LIST=$(echo $LIST | tr " " ",")
#LIST=$(echo $LIST | tr "\n" " ")
echo $LIST