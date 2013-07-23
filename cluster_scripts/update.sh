#!/bin/bash
git fetch --all
git reset --hard origin/master
chmod -f +x ./bin/*
chmod -f +x ./shbin/*.sh
chmod -f +x ./cgi-bin/*.pl
chmod -f +x ./pybin/*.py
chmod -f +x ./update.sh
chmod -f +x ./configs/genconfig.sh
chmod -f +x ./bin/embossman
cd configs
./genconfig.sh
..pybin/pyzip_files/make_pyz.sh