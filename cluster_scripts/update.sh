#!/bin/bash
svn update
chmod -f +x ./bin/*
chmod -f +x ./shbin/*.sh
chmod -f +x ./cgi-bin/*.pl
chmod -f +x ./pybin/*.py
chmod -f +x ./update.sh
chmod -f +x ./configs/genconfig.sh
cd configs
./genconfig.sh