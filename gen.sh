#!/bin/bash
# NE PAS MODIFIER DIRECTEMENT SUR LE RESEAU, UTILISER push.sh...
# sinon le statut exécutable saute.

function msg {
	echo ">> $1"
} >&2

function usage {
	msg "usage: ./$(basename $0) [-e|--extrainfo] [-t|--tag TAG] < BALISEP_FILE" 
	msg "e.g.: ./$(basename $0) --extrainfo --tag IBP < BALISEP" 
	msg "e.g.: ./$(basename $0) -t \\\${DATE_DELIVER} < BALISEP"
	exit 1
} 

export DATE_CA
export DATE_DELIVER
export PRETTY_FILE
export PRETTY_SORT
export PRETTY_EXTRAINFO

TAG=
PRETTY_EXTRAINFO=0
while (( $# > 0 )); do
	case $1 in
		-t|--tag)
			shift
			TAG=_${1:-notag}
			shift;;
		-e|--extrainfo)
			PRETTY_EXTRAINFO=1
			shift;;
		-h|--help)
			usage;;
		*)
			if [ -e "$1" ]; then
				exec < "$1"
			else
				msg "euh, kezako: \"$1\"?" 
				usage
			fi
			shift;;
	esac
done

# checks if there is sthg redirected
# -p /dev/stdin checks if stdin is an opened pipe
# -t 0 checks if stdin is a terminal
if [ -t 0 ]; then
	usage
fi

#TMP=$(mktemp tbtniv.XXXX.tmp)
#TMP="/tmp/tbtniv.$$.tmp"
TMP="/tmp/tbtniv.$(date '+%0d%0b%Y-%0kh%0M').tmp"

# delete \r chars
sed 's/\r//g' > $TMP
# redirects it to stdin again...
exec < $TMP

# normal process:
read HEADER
{ echo $HEADER | grep '^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ \t]*$'; } > /dev/null
if [ $? -ne 0 ]; then
	msg "[ERROR]: entête de fichier non valide" 
	exit 3
fi
DATE_CA=$(echo $HEADER | awk '{print $7}')
DATE_DELIVER=$(echo $HEADER | awk '{print $10 }')
msg "date CA: ${DATE_CA}" 
msg "date Livraison: ${DATE_DELIVER}" 

PRETTY_FILE=BALISEP_TB_${DATE_CA}$(eval echo ${TAG}).txt
PRETTY_SORT="Tbtniv > Bal."
sed 's/\r//g' |
 grep '^3[ 12][A-Z0-9]\{2,5\} .*$' |
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

PRETTY_FILE=BALISEP_NTB_${DATE_CA}$(eval echo ${TAG}).txt
PRETTY_SORT="Nb. > Tbtniv > Bal."
cat $TMP |
 sort -k4,4n -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > $PRETTY_FILE

