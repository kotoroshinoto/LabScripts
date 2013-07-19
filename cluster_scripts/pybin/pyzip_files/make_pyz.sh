#!/bin/bash

cd /UCHC/HPC/Everson_HPC/cluster_scripts/pybin
rm -f Pipeline.zip
zip -r Pipeline.zip Pipeline
cd pyzip_files
zip ../Pipeline.zip __main__.py
cd ..
cat pyzip_files/shebang.txt Pipeline.zip >Pipeline.pyz
chmod +x Pipeline.pyz
rm -f Pipeline.zip