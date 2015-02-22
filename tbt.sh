#!/bin/bash


# parsing with a function call, be lazy!
function get_dates_from_header {
	DATE_CA=$7
	DATE_DELIVER=${10}
}

function usage {
	# $1 contains the error to display if needed
	if [ ! "x$1" == "x" ]; then
		echo "[E] $1" >&2
	fi
	echo "usage fn" >&2
	exit 1
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
DATE=$(date '+%0d%0b%Y-%0kh%0M')

while (($# > 0)); do
	case "$1" in
	-b)
		SEP_BLOCKS=$((!(($SEP_BLOCKS))))
		shift;;
	-h)
		usage;;
	-l)
		SEP_LINES=$((!(($SEP_LINES))))
		shift;;
	-n)
		if ! [[ $2 =~ ^[0-9]+$ ]]; then
			usage "le champ après -n doit être un nombre"
		fi
		MAX_BEACONS_PER_LINE=$2
		shift; shift;;
	-p)
		
		shift; shift;;
	*)
		if [ -e "$1" ] && [ -f "$1" ]; then
			INPUT="$1"
			shift
		else
			usage "champ $1 de type inconnu"
		fi;;
	esac
done
MAXLEN=$((6 * (MAX_BEACONS_PER_LINE > 0 ? MAX_BEACONS_PER_LINE : 1) ))

if [ ! -e "${INPUT}" ]; then
	usage "aucun nom de fichier BALISEP transmis"
fi
check_header "${INPUT}"
get_dates_from_header $HEADER
info "Date CA: ${DATE_CA}, livraison: ${DATE_DELIVER}" 

WD="./${DATE}_CA${DATE_CA}/"
{ mkdir -p "${WD}"; } > /dev/null
if [ $? -ne 0 ]; then
	usage "impossible de créer le repertoire ${WD}"
fi
info "Création du répertoire [${WD:2:${#WD}-3}]"

# with stats inside, 4 cols
# >> BEACON TBTNIV_LEN TBTNIV TBTNIV_OCC
RAW="${WD}.raw.txt"
# >> TBTNIV_OCC TBTNIV
TBTNIV_STATS="${WD}.tbtniv.stats.txt"
# tbtniv used in that session
# >> TBTNIV (only)
TBTNIV="${WD}tbtniv.txt"
# same but sorted in two different ways
BALISEP_TB="${WD}balisep_tbtniv_balise.txt"
BALISEP_NTB="${WD}balisep_nb_tbtniv_balise.txt"
TMP="${WD}.tmp.txt"

# extract data from balisep file
#awk -f raw.tbtniv.awk "${INPUT}" > "${RAW}"
#sort -k2,2n -k3,3 "${RAW}" | awk '{ print $3 }' | uniq -c > "${TBTNIV_STATS}"
awk -f raw.tbtniv.awk "${INPUT}" > "${RAW}"
sort -k2,2n -k3,3 "${RAW}" | awk '{ print $3 }' | uniq -c > "${TBTNIV_STATS}"
awk '{ print $2 }' "${TBTNIV_STATS}" > "${TBTNIV}"

declare -A ary
ary[1,"FILE"]="${BALISEP_TB}"
ary[1,"SORT_COMMENT"]="Tbtniv > Bal."
ary[1,"SORT"]="-k2,2n -k3,3 -k1,1"

ary[2,"FILE"]="${BALISEP_NTB}"
ary[2,"SORT_COMMENT"]="Nb. > Tbtniv > Bal."
ary[2,"SORT"]="-k4,4n -k2,2n -k3,3 -k1,1"

for i in {1..2}; do
	DST=${ary[$i,"FILE"]}
	COMMENT=${ary[$i,"SORT_COMMENT"]}
	info "\"${COMMENT}\" dans [${DST##*/}]"

	sort ${ary[$i,"SORT"]} < "${RAW}" > "${TMP}"
	awk -f pr.awk "STEP=0" "${TBTNIV_STATS}" "EMPTYLINE=${SEP_LINES}"\
		"SPLIT=${SEP_BLOCKS}" "MAXLEN=${MAXLEN}" "STEP=1" "${TMP}"\
		> "${DST}"
done
