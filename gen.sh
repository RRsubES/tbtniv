#!/bin/bash
# export BALISEP_FILE_ALPHA=BALISEP0.txt
# ./gen.sh < BALISEP
# or BALISEP_FILE_ALPHA=BALISEP0.txt ./gen.txt < BALISEP

#TMP=$(mktemp)
TMP="/tmp/tbtniv.$$.tmp"

awk -f filter.awk | 
 awk -f extract.awk |
 awk -f process.awk > $TMP

export PRETTY_FILE=${BALISEP_FILE_ALPHA:-BALISEP_ALPHA.txt}
cat $TMP | sort -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=${BALISEP_FILE_NUMBER:-BALISEP_NUMBER.txt}
cat $TMP | sort -k4,4n -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > $PRETTY_FILE
