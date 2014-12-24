#!/bin/bash

function usage {
	echo ">> usage: ./$(basename $0) [-t|--tag TAG] < BALISEP_FILE" >&2
	exit 1
}

# checks if there is sthg redirected
# -p /dev/stdin checks if stdin is an opened pipe
# -t 0 checks if stdin is a terminal
if [ -t 0 ]; then
	usage
fi

TAG=
while (( $# > 0 )); do
	case $1 in
		-t|--tag)
			shift
			TAG=_${1:-notag}
			shift;;
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

read HEADER
{ echo $HEADER | grep '^FORMAT : STIP VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} PART : BALISEP .*$'; } > /dev/null
if [ $? -ne 0 ]; then
	echo ">> entête de fichier non valide" >&2
	exit 3
fi
DATE_CA=$(echo $HEADER | awk '{print $7}')
echo ">> date CA: ${DATE_CA}" >&2

PRETTY_FILE=BALISEP_TB_${DATE_CA}${TAG}.txt
PRETTY_SORT="Tbtniv > Bal."
grep '^3[ 12][A-Z0-9]\{2,5\} .*$' |
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=BALISEP_NTB_${DATE_CA}${TAG}.txt
PRETTY_SORT="Nb. > Tbtniv > Bal."
cat $TMP |
 sort -k4,4n -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

