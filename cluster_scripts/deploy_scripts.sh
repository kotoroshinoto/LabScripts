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
SRCDIR=/UCHC/HPC/Everson_HPC/custom_scripts/src/labscripts-code/cluster_scripts/
DESTDIR=/UCHC/HPC/Everson_HPC/custom_scripts/bin
CURPIP=current_pipeline

#deploy "current pipeline"
chmod +x $SRCDIR/current_pipeline/*.sh 
FILES=`ls $SRCDIR/current_pipeline/*.sh`
FILES=$(echo $FILES | tr "\n" " ")
linkfiles $DESTDIR $FILES

#deploy "modulefiles"
linkfiles /UCHC/HPC/Everson_HPC/modulefiles/EversonLabBiotools/ /UCHC/HPC/Everson_HPC/custom_scripts/src/labscripts-code/modulefiles/EversonLabBiotools/1.0