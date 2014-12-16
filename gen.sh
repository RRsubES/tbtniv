#!/bin/bash
# export BALISEP_FILE_ALPHA=BALISEP0.txt
# ./gen.sh < BALISEP
# or BALISEP_FILE_ALPHA=BALISEP0.txt ./gen.txt < BALISEP

#TMP=$(mktemp tbtniv.XXXX.tmp)
#TMP="/tmp/tbtniv.$$.tmp"
TMP="/tmp/tbtniv.$(date '+%d%b%Y-%kh%M').tmp"

export PRETTY_FILE
export PRETTY_SORT

PRETTY_FILE=${BALISEP_FILE_ALPHA:-BALISEP_ALPHA.txt}
PRETTY_SORT="TBTNIV > Bal."
awk -f filter.awk | 
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=${BALISEP_FILE_NUMBER:-BALISEP_NUMBER.txt}
PRETTY_SORT="Nb. > TBTNIV > Bal."
cat $TMP | sort -k4,4n -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > $PRETTY_FILE
