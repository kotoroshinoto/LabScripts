#!/bin/bash

rm Pipeline.zip
cd Pipeline
zip -r ../Pipeline.zip ./*
cd ..
cat shebang.txt Pipeline.zip >Pipeline.pyz
chmod +x Pipeline.pyz