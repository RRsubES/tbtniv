#!/bin/bash
# NE PAS MODIFIER DIRECTEMENT SUR LE RESEAU, UTILISER push.sh...
# sinon le statut exécutable saute.

export DATE_CA
export DATE_DELIVER
export PRETTY_FILE
export PRETTY_SORT
export PRETTY_MAXLEN
export PRETTY_EMPTYLINE
export PRETTY_SPLIT

TAG=
PRETTY_EMPTYLINE=0
PRETTY_SPLIT=0
NR_BEACONS_MAX=5

function msg {
	echo ">> $1"
} >&2

function err {
	msg "[ERR]: $1"
}

# parsing with a function call, be lazy!
function get_dates_from_header {
	DATE_CA=$7
	DATE_DELIVER=${10}
}

function usage {
	msg "usage: ./$(basename $0) [-bl] [-n NB] [-t TAG] < BALISEP_FILE" 
	msg ""
	msg "Paramètres:"
	msg "-b     : separe les blocs par une interligne vide"
	msg "-l     : separe les lignes par une interligne vide"
	msg "-n NB  : nombre max de balises affichées par ligne"
	msg "         (NB=${NR_BEACONS_MAX} par défaut)"
	msg "-t TAG : ajout d'un tag spécifié par l'utilisateur, "
	msg "         peut être \\\${DATE_DELIVER} ou \\\${DATE_CA}"
	msg "         ou du texte brut (espaces remplacés par _)." 
	msg ""
	msg "e.g.: ./$(basename $0) -lt ibp < BALISEP" 
	msg "(ou)  ./$(basename $0) -l -t ibp < BALISEP" 
	msg ""
	msg "e.g.: ./$(basename $0) -t livree_le_\\\${DATE_DELIVER} < BALISEP"
	msg "(ou)  ./$(basename $0) -t \"livree le \\\${DATE_DELIVER}\" < BALISEP"
	msg ""
	msg "e.g.: ./$(basename $0) -lbn 4 -t ibp < BALISEP"
	msg "(ou)  ./$(basename $0) -l -b -n 4 -t ibp < BALISEP"
	exit 1
} 

while getopts ":t:n:blh" opt; do
	case $opt in
		t)
			TAG=${OPTARG:-notag};;
		l)
			PRETTY_EMPTYLINE=$((!(($PRETTY_EMPTYLINE))));;
		n)
			NR_BEACONS_MAX=${OPTARG:-NR_BEACONS_MAX};;
		b)
			PRETTY_SPLIT=$((!(($PRETTY_EMPTYLINE))));;
		\:|\?|h)
			usage;;
	esac
done
shift $(($OPTIND - 1))
PRETTY_MAXLEN=$((6 * (NR_BEACONS_MAX > 0 ? NR_BEACONS_MAX : 1) ))

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
#replace spaces with underscores
#eval TAG=${TAG:+_$TAG}
eval TAG=${TAG:+_${TAG// /_}}

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

