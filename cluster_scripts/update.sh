#!/bin/bash
git fetch --all
git reset --hard origin/master
function EXPERM{
	DIR=$1;
	shift;
	for EXT in "$@"
	do 
	find ./$DIR -type f -path *.$EXT -exec chmod -f +x {} \;
	done	
}
function EXPERMALL{
	DIR=$1;
	shift;
	find ./$DIR -type f -exec chmod -f +x {} \;	
}
EXPERMALL ./bin
chmod -f +x ./update.sh
chmod -f +x ./configs/genconfig.sh
chmod -f +x ./bin/embossman
cd configs
./genconfig.sh
../pybin/pyzip_files/make_pyz.sh