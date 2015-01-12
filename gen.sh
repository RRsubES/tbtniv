#!/bin/bash
# NE PAS MODIFIER DIRECTEMENT SUR LE RESEAU, UTILISER push.sh...
# sinon le statut exécutable saute.

function msg {
	echo ">> $1"
} >&2

function err {
	msg "[ERROR]: $1"
}

function usage {
	msg "usage: ./$(basename $0) [-e] [-t TAG] < BALISEP_FILE" 
	msg ""
	msg "-e    : DATE_CA et DATE_DELIVER ajoutées à l'entête"
	msg "-t TAG: ajout d'un tag spécifié par l'utilisateur"
	msg "        peut être \\\$DATE_DELIVER ou \\\$DATE_CA"
	msg "        ou du texte brut (sans espace)." 
	msg ""
	msg "e.g.: ./$(basename $0) -et IBP < BALISEP" 
	msg "e.g.: ./$(basename $0) -t \\\${DATE_DELIVER} < BALISEP"
	exit 1
} 

# parsing with a function call, be lazy!
function get_dates_from_header {
	DATE_CA=$7
	DATE_DELIVER=${10}
}

export DATE_CA
export DATE_DELIVER
export PRETTY_FILE
export PRETTY_SORT
export PRETTY_EXTRAINFO

TAG=
PRETTY_EXTRAINFO=0
while getopts ":t:eh" opt; do
	case $opt in
		t)
			TAG=_${OPTARG:-notag};;
		e)
			PRETTY_EXTRAINFO=1;;
		\:|\?|h)
			usage;;
	esac
done
shift $(($OPTIND - 1))

# checks if there is sthg redirected
# -p /dev/stdin checks if stdin is an opened pipe
# -t 0 checks if stdin is a terminal
if [ -t 0 ]; then
	usage
fi

#TMP=$(mktemp tbtniv.XXXX.tmp)
#TMP="/tmp/tbtniv.$$.tmp"
TMP="/tmp/tbtniv.$(date '+%0d%0b%Y-%0kh%0M').tmp"

# normal process:
HEADER_TEMPLATE='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
read HEADER
{ echo $HEADER | sed 's/\r//g' | grep "$HEADER_TEMPLATE"; } > /dev/null
if [ $? -ne 0 ]; then
	err "entête de fichier non valide, forme retenue:" 
	err "$(echo ${HEADER_TEMPLATE:1:${#HEADER_TEMPLATE}-2} | sed 's/\\//g')"
	exit 3
fi
get_dates_from_header $HEADER
msg "date CA: ${DATE_CA}" 
msg "date Livraison: ${DATE_DELIVER}" 

PRETTY_FILE="BALISEP_TB_${DATE_CA}$(eval echo ${TAG}).txt"
PRETTY_SORT="Tbtniv > Bal."
sed 's/\r//g' |
# [A-Z0-9*]\{1,2\} because some sectors have a single letter name
#grep '^3[ 12][A-Z0-9]\{2,5\} \+\([0-9*]\{3\} [A-Z0-9*]\{1,2\} \+\)\{1,3\}$' |
 grep '^3[ 12][A-Z0-9]\{2,5\} \+\(\(\*\*\*\|[0-9]\{3\}\) \(\*\*\|[A-Z0-9]\{1,2\}\) \+\)\{1,3\}$' |
#grep '^3[ 12][A-Z0-9]\{2,5\}.*$' |
 awk -f extract.awk |
 awk -f process.awk |
 tee $TMP |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > "$PRETTY_FILE"

PRETTY_FILE="BALISEP_NTB_${DATE_CA}$(eval echo ${TAG}).txt"
PRETTY_SORT="Nb. > Tbtniv > Bal."
cat $TMP |
 sort -k4,4n -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > "$PRETTY_FILE"

