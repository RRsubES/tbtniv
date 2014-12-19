#!/bin/bash
# ./gen.sh < BALISEP

#TMP=$(mktemp tbtniv.XXXX.tmp)
#TMP="/tmp/tbtniv.$$.tmp"
TMP="/tmp/tbtniv.$(date '+%d%b%Y-%kh%M').tmp"

export DATE_CA
export PRETTY_FILE
export PRETTY_SORT

read HEADER
DATE_CA=$(echo $HEADER | awk '{print $7}')
echo ">> date CA: ${DATE_CA}" >&2

PRETTY_FILE=BALISEP_TB_${DATE_CA}.txt
PRETTY_SORT="Tbtniv > Bal."
awk -f filter.awk | 
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=BALISEP_NTB_${DATE_CA}.txt
PRETTY_SORT="Nb. > Tbtniv > Bal."
cat $TMP | sort -k4,4n -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > $PRETTY_FILE
