shell=`/bin/basename \`/bin/ps -p $$ -ocomm=\``
MODULE_INIT="/UCHC/HPC/Everson_HPC/Modules/3.2.10/init"
if [ -f $MODULE_INIT/$shell ]
then
  . $MODULE_INIT/$shell
else
  . $MODULE_INIT/init/sh
fi
