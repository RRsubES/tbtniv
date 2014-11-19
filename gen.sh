#!/bin/bash


TMP="/tmp/tbtniv.tmp"

# gen.sh < input > output
awk -f filter.awk | 
 awk -f extract.awk |
 awk -f process.awk | tee $TMP | sort -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > BALISEP_ALPHA.txt

cat $TMP | sort -k4,4n -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > BALISEP_NUMBER.txt


