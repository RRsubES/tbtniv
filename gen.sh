#!/bin/bash

OVERWRITE=0
while (( $# > 0 )); do
	case $1 in
		-o|--overwrite)
			shift
			OVERWRITE=1;;
		*)
			echo ">> usage: ./$(basename $0) [-o|--overwrite] < BALISEP_FILE" >&2
			exit 1;; 
	esac
done

#TMP=$(mktemp tbtniv.XXXX.tmp)
#TMP="/tmp/tbtniv.$$.tmp"
TMP="/tmp/tbtniv.$(date '+%0d%0b%Y-%0kh%0M').tmp"

export DATE_CA
export PRETTY_FILE
export PRETTY_SORT

function check_file {
	if [ $OVERWRITE -eq 0 -a -f $1 ]; then
		echo ">> $1 existe, abandon" >&2
		exit 2
	fi
}

read HEADER
DATE_CA=$(echo $HEADER | awk '{print $7}')
echo ">> date CA: ${DATE_CA}" >&2

PRETTY_FILE=BALISEP_TB_${DATE_CA}.txt
PRETTY_SORT="Tbtniv > Bal."
check_file $PRETTY_FILE
grep '^3[ 12][A-Z0-9]\{2,5\} .*$' |
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=BALISEP_NTB_${DATE_CA}.txt
PRETTY_SORT="Nb. > Tbtniv > Bal."
check_file $PRETTY_FILE

cat $TMP | sort -k4,4n -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > $PRETTY_FILE
