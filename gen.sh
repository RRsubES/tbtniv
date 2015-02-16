#!/bin/bash
# NE PAS MODIFIER DIRECTEMENT SUR LE RESEAU, UTILISER push.sh...
# sinon le statut exécutable saute.

export PRETTY_FILE
export PRETTY_SORT
export PRETTY_MAXLEN
export PRETTY_EMPTYLINE
export PRETTY_SPLIT
export PRETTY_NR_TBTNIV

TAG=
PRETTY_EMPTYLINE=0
PRETTY_SPLIT=0
MAX_BEACONS_PER_LINE=5
WD=

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
	msg "         (NB=${MAX_BEACONS_PER_LINE} par défaut)"
	msg "-f     : affiche le nom des fichiers créés sur"
	msg "         la sortie standard"
	msg "-d DIR : spécifie le répertoire destination où seront"
	msg "         stockés les fichiers générés; souvent avec -f."
	msg "-D     : comme -d sauf que DIR=./PID.DATE"
	msg "-t TAG : ajout d'un tag spécifié par l'utilisateur, "
	msg "         (TAG=vide par défaut), peut-être aussi bien" 
	msg "         des variables extraites du fichier en entrée"
	msg "         que du texte brut (les espaces seront remplacés" 
	msg "         par _)." 
	msg "         les variables extraites sont :" 
	msg "         - DATE_DELIVER" 
	msg "         - DATE_CA" 
	msg "         - PRETTY_NR_TBTNIV ..." 
	msg "         Pour ce faire, les écrire dans le tag sous la forme" 
	msg "         \\\${DATE_DELIVER} ou \\\${DATE_CA}" 
	msg ""
	msg "e.g.: ./$(basename $0) -lt ibp < BALISEP" 
	msg "(ou)  ./$(basename $0) -l -t ibp < BALISEP" 
	msg ""
	msg "e.g.: ./$(basename $0) -t livree_le_\\\${DATE_DELIVER} < BALISEP"
	msg "(ou)  ./$(basename $0) -t \"livree le \\\${DATE_DELIVER}\" < BALISEP"
	msg ""
	msg "e.g.: ./$(basename $0) -lbn 4 -t \\\${PRETTY_NR_TBTNIV} < BALISEP"
	msg "(ou)  ./$(basename $0) -l -b -n 4 -t \\\${PRETTY_NR_TBTNIV} < BALISEP"
	exit 1
} 

while getopts ":t:n:d:bDflh" opt; do
	case $opt in
		D)
			WD="./$$.$(date '+%0d%0b%Y-%0kh%0M')"
			mkdir -p "${WD}" 
			if [ $? -ne 0 ]; then
				err "problème à la création de ${WD}"
				exit 3
			fi
			;;
		d)
			eval WD="${OPTARG%/}"
			if [ "${WD}" == "." ]; then
				WD=
				break
			fi
			if [ -e "${WD}" -a ! -d "${WD}" ]; then
				err "${WD} doit être un répertoire et ne pas exister"
				exit 3
			fi
			mkdir -p "${WD}" 
			if [ $? -ne 0 ]; then
				err "problème à la création de ${WD}"
				exit 3
			fi
			;;
		t)
			TAG=${OPTARG:-notag};;
		l)
			PRETTY_EMPTYLINE=$((!(($PRETTY_EMPTYLINE))));;
		n)
			MAX_BEACONS_PER_LINE=${OPTARG:-MAX_BEACONS_PER_LINE};;
		f)	
			RETURN_FILES=;;
#RETURN_FILES=1;;
		b)
			PRETTY_SPLIT=$((!(($PRETTY_EMPTYLINE))));;
		\:|\?|h)
			usage;;
	esac
done
shift $(($OPTIND - 1))
PRETTY_MAXLEN=$((6 * (MAX_BEACONS_PER_LINE > 0 ? MAX_BEACONS_PER_LINE : 1) ))
WD=${WD:+${WD}/}

# checks if there is sthg redirected
# -p /dev/stdin checks if stdin is an opened pipe
# -t 0 checks if stdin is a terminal
if [ -t 0 ]; then
	usage
fi

TMP="/tmp/tbtniv.$$.$(date '+%0d%0b%Y-%0kh%0M').tmp"

# normal process:
HEADER_TEMPLATE='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
read HEADER
{ echo $HEADER | sed 's/\r//g' | grep "$HEADER_TEMPLATE"; } > /dev/null
if [ $? -ne 0 ]; then
	err "entête de fichier non valide, forme retenue:" 
	err "$(echo ${HEADER_TEMPLATE:1:${#HEADER_TEMPLATE}-2} | sed 's/\\//g')"
	exit 3
fi

#creating the base temporary file for all next process
sed 's/\r//g' |
 # [A-Z0-9*]\{1,2\} because some sectors have a single letter name
 grep '^3[ 12][A-Z0-9]\{2,5\} \+\(\(\*\*\*\|[0-9]\{3\}\) \(\*\*\|[A-Z0-9]\{1,2\}\) \+\)\{1,3\}$' |
 awk -f extract.awk |
 awk -f process.awk > "$TMP"

get_dates_from_header $HEADER
msg "Date CA: ${DATE_CA}, livraison: ${DATE_DELIVER}" 
#
PRETTY_NR_TBTNIV=$(cut -d' ' -f 3 < "$TMP" | sort | uniq -c | wc -l)
NR_BEACONS=$(wc -l < "$TMP")
msg "Statistiques: ${PRETTY_NR_TBTNIV} tbtniv(s), ${NR_BEACONS} balise(s)"
#evaluate the tag, cannot be done before...
#replace TAG with the variable content if needed, otherwise add _TAG or nothing
#replace spaces with underscores
#eval TAG=${TAG:+_$TAG}
eval TAG=${TAG:+_${TAG// /_}}

declare -A ary
ary[1,"PRETTY_FILE"]="BALISEP_TB_${DATE_CA}${TAG}.txt"
ary[1,"PRETTY_SORT"]="Tbtniv > Bal."
ary[1,"SORT"]="-k2,2n -k3,3 -k1,1"

ary[2,"PRETTY_FILE"]="BALISEP_NTB_${DATE_CA}${TAG}.txt"
ary[2,"PRETTY_SORT"]="Nb. > Tbtniv > Bal."
ary[2,"SORT"]="-k4,4n -k2,2n -k3,3 -k1,1"

for i in {1..2}; do
	PRETTY_FILE=${WD}${ary[$i,"PRETTY_FILE"]}
	PRETTY_SORT=${ary[$i,"PRETTY_SORT"]}
	sort ${ary[$i,"SORT"]} < "$TMP" |
	 cut -d' ' -f 1,3-5 |
	 awk -f pretty.awk > "${PRETTY_FILE}"
#if [ -n ${RETURN_FILES} ]; then
	# passes the test if the variable is defined
	if [ -v RETURN_FILES ]; then
		echo "${PRETTY_FILE}" 
	fi
done

