#!/bin/bash

function usage {
	echo ">> usage: ./$(basename $0) [-c|--checkfile] < BALISEP_FILE" >&2
	exit 1

}

# checks if there is sthg redirected
# -p /dev/stdin checks if stdin is an opened pipe
# -t 0 checks if stdin is a terminal
if [ -p /dev/stdin -o -t 0 ]; then
	usage
fi

OVERWRITE=1
while (( $# > 0 )); do
	case $1 in
		-c|--checkfile)
			shift
			OVERWRITE=0;;
		-h|--help|*)
			usage;;
	esac
done

#TMP=$(mktemp tbtniv.XXXX.tmp)
#TMP="/tmp/tbtniv.$$.tmp"
TMP="/tmp/tbtniv.$(date '+%0d%0b%Y-%0kh%0M').tmp"

export DATE_CA
export PRETTY_FILE
export PRETTY_SORT

function check_dst_file {
	if [ $OVERWRITE -eq 0 -a -f $PRETTY_FILE ]; then
		echo ">> $PRETTY_FILE existe, abandon" >&2
		exit 2
	fi
}

read HEADER
DATE_CA=$(echo $HEADER | awk '{print $7}')
echo ">> date CA: ${DATE_CA}" >&2

PRETTY_FILE=BALISEP_TB_${DATE_CA}.txt
PRETTY_SORT="Tbtniv > Bal."
check_dst_file 
grep '^3[ 12][A-Z0-9]\{2,5\} .*$' |
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=BALISEP_NTB_${DATE_CA}.txt
PRETTY_SORT="Nb. > Tbtniv > Bal."
check_dst_file
cat $TMP | sort -k4,4n -k2,2n -k3,3 -k1,1 | cut -d' ' -f 1,3-5 | awk -f pretty.awk > $PRETTY_FILE
