#!/bin/bash

bedtools intersect -u -abam $1 -b $2 >$3