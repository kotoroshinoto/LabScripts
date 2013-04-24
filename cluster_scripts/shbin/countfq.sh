#!/bin/bash

for arg in "$@"
do
	var=`wc -l $arg | cut -f1 -d' '`
	var=$(($var/4))
	echo -e "$arg\t$var"
done
