#!/bin/bash

# parsing with a function call, be lazy!
function get_dates_from_header {
	# echo date is DD-MM-YY, changing it to YYYY-MM-DD
	DATE_CA=$(echo ${7} | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
	DATE_DELIVER=$(echo ${10} | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
}

function usage {
	# $1 contains the exit error code
	# $2 contains the error msg to display if needed
	if [ ! "x$2" == "x" ]; then
		echo "[E] $2" >&2
	fi
	cat >&2 <<EOF
usage: ./$(basename $0) [-blh] [-n NB] BALISEP_FIC
Paramètres:
-b	    : annule la séparation des blocs de balises.
-l    	    : sépare chaque ligne par une ligne vide.
-h	    : affiche l'aide
-n NB=${MAX_BEACONS_PER_LINE}     : spécifie le nombre max de balises affichées par ligne.
BALISEP_FIC : spécifie le nom/chemin vers le fichier BALISEP à traiter.

Les fichiers générés seront dans un répertoire créé dans le repertoire courant,
    ayant pour nom: {DATE_HEURE_DU_JOUR}_CA{DATE_CA}.

e.g.: ./$(basename $0) -b -l -n 16 BALISEP.15mar 
EOF
	exit $1
}

function check_header {
	#check balisep header file $1
	HEADER_TEMPLATE='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
	HEADER=$(head -1 "$1")
	{ echo "${HEADER}" | sed 's/\r//g' | grep "$HEADER_TEMPLATE"; } > /dev/null
	if [ $? -ne 0 ]; then
		info "entête de fichier non valide, forme retenue:" 
		info "$(echo ${HEADER_TEMPLATE:1:${#HEADER_TEMPLATE}-2} | sed 's/\\//g')"
		exit 3
	fi
}

function info {
	echo "$1"
} >&2

SEP_LINES=0
SEP_BLOCKS=1
MAX_BEACONS_PER_LINE=5
DATE_CA=
DATE_DELIVER=
DATE=$(date '+%Y-%0m-%0d_%0kh%0M')

while (($# > 0)); do
	case "$1" in
	-b)
		SEP_BLOCKS=$((!(($SEP_BLOCKS))))
		shift;;
	-h)
		usage 1;;
	-l)
		SEP_LINES=$((!(($SEP_LINES))))
		shift;;
	-n)
		if ! [[ $2 =~ ^[0-9]+$ ]]; then
			usage 10 "le champ suivant -n doit être un nombre"
		fi
		MAX_BEACONS_PER_LINE=$2
		shift; shift;;
	*)
		if [ -e "$1" ] && [ -f "$1" ]; then
			INPUT="$1"
			shift
		else
			usage 11 "champ $1 de type inconnu"
		fi;;
	esac
done
MAXLEN=$((6 * (MAX_BEACONS_PER_LINE > 0 ? MAX_BEACONS_PER_LINE : 1) ))

if [ ! -e "${INPUT}" ]; then
	usage 12 "aucun nom de fichier BALISEP transmis"
fi
check_header "${INPUT}"
get_dates_from_header $HEADER
info "Date CA: ${DATE_CA}, livrée le: ${DATE_DELIVER}" 

WD="./${DATE}_CA${DATE_CA}/"
if [ -e "${WD}" ]; then
	usage 14 "repertoire ${WD} déjà utilisé, le supprimer ou attendre un peu"
fi
{ mkdir -p "${WD}"; } > /dev/null
if [ $? -ne 0 ]; then
	usage 15 "impossible de créer le repertoire ${WD}"
fi
info "Résultats disponibles dans [${WD:2:${#WD}-3}]"
# duplicate source file in ${WD}
{ cp "${INPUT}" "${WD}BALISEP"; } > /dev/null

# 4 columns, data extracted from balisep. (hidden)
# >> BEACON TBTNIV_LEN TBTNIV TBTNIV_OCC
DATA="${WD}.data.txt"
# >> TBTNIV_OCC TBTNIV
TBTNIV_STATS="${WD}.tbtniv.stats.txt"
# tbtniv used in that session
# >> TBTNIV (only)
TBTNIV="${WD}tbtniv.txt"
# ${DATA} sorted in two different ways and displayed with pr.awk
BALISEP_TB="${WD}balisep_tbtniv_balise.txt"
BALISEP_NTB="${WD}balisep_nb_tbtniv_balise.txt"
# temporary file (hidden)
TMP="${WD}.tmp.txt"

# extract data from balisep file
#sed 's/\r//g' "${INPUT}" |
awk -f raw.tbtniv.awk "${INPUT}" | sort -k1,1 | tee "${DATA}" |
	sort -k2,2n -k3,3 | awk '{ print $3 }' | uniq -c > "${TBTNIV_STATS}"
#| cut -d' ' -f 3 | uniq -c > "${TBTNIV_STATS}"
# erase stats
awk '{ print $2 }' "${TBTNIV_STATS}" > "${TBTNIV}"

declare -A ary
ary[1,"FILE"]="${BALISEP_TB}"
ary[1,"SORT_COMMENT"]="Tbtniv > Bal."
ary[1,"SORT"]="-k2,2n -k3,3 -k1,1"

ary[2,"FILE"]="${BALISEP_NTB}"
ary[2,"SORT_COMMENT"]="Nb. > Tbtniv > Bal."
ary[2,"SORT"]="-k4,4n -k2,2n -k3,3 -k1,1"

info "Tri:"
for i in {1..2}; do
	DST=${ary[$i,"FILE"]}
	COMMENT=${ary[$i,"SORT_COMMENT"]}
	info "	- \"${COMMENT}\" dans [${DST##*/}]"

	sort ${ary[$i,"SORT"]} < "${DATA}" > "${TMP}"
	awk -f pr.awk "STEP=0" "${TBTNIV_STATS}" "EMPTYLINE=${SEP_LINES}"\
		"SPLIT=${SEP_BLOCKS}" "MAXLEN=${MAXLEN}" "STEP=1" "${TMP}"\
		> "${DST}"
	rm -f "${TMP}" 2>&1 > /dev/null
done
