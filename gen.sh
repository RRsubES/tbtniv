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
	msg "usage: ./$(basename $0) [-eis] [-l LEN] [-t TAG] < BALISEP_FILE" 
	msg ""
	msg "-e    : separe les lignes par une interligne vide"
	msg "-i    : DATE_CA et DATE_DELIVER ajoutées à l'entête"
	msg "-s    : separe les blocs par une interligne vide"
	msg "-l LEN: taille maximale de la chaine des balises )"
	msg "        (LEN=96 par défaut)"
	msg "-t TAG: ajout d'un tag spécifié par l'utilisateur, "
	msg "        peut être DATE_DELIVER ou DATE_CA ou du texte"
	msg "        brut (sans espace)." 
	msg ""
	msg "e.g.: ./$(basename $0) -ie -t ibp < BALISEP" 
	msg "e.g.: ./$(basename $0) -t ibp2015 < BALISEP" 
	msg "e.g.: ./$(basename $0) -t DATE_DELIVER < BALISEP"
	msg "e.g.: ./$(basename $0) -t DATE_CA < BALISEP"
	msg "e.g.: ./$(basename $0) -sl 60 < BALISEP"
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
export PRETTY_MAXLEN
export PRETTY_EMPTYLINE
export PRETTY_SPLIT

TAG=
PRETTY_EXTRAINFO=0
PRETTY_EMPTYLINE=0
PRETTY_SPLIT=0
PRETTY_MAXLEN=$((16 * 6))
while getopts ":t:l:eihs" opt; do
	case $opt in
		t)
			TAG=${OPTARG:-notag};;
		e)
			PRETTY_EMPTYLINE=1;;
		i)
			PRETTY_EXTRAINFO=1;;
		l)
			PRETTY_MAXLEN=${OPTARG:-PRETTY_MAXLEN};;
		s)
			PRETTY_SPLIT=1;;
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
#evaluate the tag, cannot be done before...
#replace TAG with the variable content if needed, otherwise add _TAG or nothing
#!TAG got replaced by the content of the variable whose name is in TAG
TAG=${TAG:+_${!TAG:-$TAG}}

PRETTY_FILE="BALISEP_TB_${DATE_CA}${TAG}.txt"
PRETTY_SORT="Tbtniv > Bal."
sed 's/\r//g' |
# [A-Z0-9*]\{1,2\} because some sectors have a single letter name
 grep '^3[ 12][A-Z0-9]\{2,5\} \+\(\(\*\*\*\|[0-9]\{3\}\) \(\*\*\|[A-Z0-9]\{1,2\}\) \+\)\{1,3\}$' |
 awk -f extract.awk |
 awk -f process.awk |
 tee "$TMP" |
 sort -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > "$PRETTY_FILE"

PRETTY_FILE="BALISEP_NTB_${DATE_CA}${TAG}.txt"
PRETTY_SORT="Nb. > Tbtniv > Bal."
cat "$TMP" |
 sort -k4,4n -k2,2n -k3,3 -k1,1 |
 cut -d' ' -f 1,3-5 |
 awk -f pretty.awk > "$PRETTY_FILE"

