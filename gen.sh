#!/bin/bash

function usage {
	# $1 contains the exit error code
	# $2 contains the error msg to display if needed
	if [ ! "x$2" == "x" ]; then
		err "$2"
	fi
	cat >&2 <<EOF
usage: ./$(basename $0) [-b] [-l] [-h] [-n NB] [-p PREFIX ] BALISEP_1 BALISEP_2...
Paramètres:
-b	    : sépare chaque bloc de tbtniv par une interligne.
-l    	    : sépare chaque ligne par une interligne.
-h	    : affiche l'aide
-n NB=${MAX_BEACONS_PER_LINE}     : spécifie le nombre max de balises affichées par ligne.
-p PREFIX   : ajoute PREFIX au nom du répertoire.
BALISEP_N   : spécifie le nom du ou des fichier(s) à traiter.

Les fichiers générés seront dans un répertoire créé dans le repertoire courant,
    ayant pour nom: {PREFIX_}{DATE_HEURE_DU_JOUR}_CA{DATE_CA}.

e.g.: ./$(basename $0) -b -l -n 10 BALISEP.15fev -n 15 -p rr BALISEP.15mar 
EOF
	exit $1
}

function is_balisep {
	local HEADER_TEMPLATE='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
	{ head -1 "$1" | sed 's/\r//g' | grep "$HEADER_TEMPLATE"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "entête de fichier non valide, forme retenue:" 
		# err "$(echo ${HEADER_TEMPLATE:1:-2} | sed 's/\\//g')"
		err "$(echo ${HEADER_TEMPLATE:1:${#HEADER_TEMPLATE}-3} | sed 's/\\//g')"
		return 1
	fi
	return 0
}

function info {
	echo "$1"
} >&2

function err {
	echo "[E]${INPUT:+${INPUT#*/} :} $1"
} >&2

# Default values
SEP_LINES=0
SEP_BLOCKS=0
MAX_BEACONS_PER_LINE=5
WD_PREFIX=

INPUT=
DATE_GEN=$(date '+%Y-%0m-%0d_%0kh%0M')

function process_balisep {
	# $1 = BALISEP file
	# Set instance values
	INPUT="$1"
	# better to keep DATE_GEN once for the whole instance,
	# much easier to complete filenames...
	MAXLEN=$((6 * MAX_BEACONS_PER_LINE))
	# echo date is DD-MM-YY, changing it to YYYY-MM-DD
	# DATE_CA=$(head -1 "${INPUT}" | awk '{print $7}' | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
	DATE_CA=$(head -1 "${INPUT}" | tr -s ' ' | cut -d' ' -f7 | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
	BEACON_NR=
	TBTNIV_NR=

	info "* ${INPUT}: date CA ${DATE_CA}" 

	# create Working Directory
	WD="./${WD_PREFIX:+${WD_PREFIX}_}${DATE_GEN}_CA${DATE_CA}/"
	if [ -e "${WD}" ]; then
		err "repertoire ${WD} déjà utilisé, abandon."
		return 10
	fi
	{ mkdir -p "${WD}"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "impossible de créer le repertoire ${WD}"
		return 11
	fi
	# info "  Résultats disponibles dans [${WD:2:-1}]"
	# does not work in my Cygwin, bash version probly outdated
	info "  Résultats disponibles dans [${WD:2:${#WD}-3}]"

	# >> BEACON TBTNIV_LEN TBTNIV TBTNIV_OCCURRENCES
	DATA="${WD}.data.txt"
	# >> TBTNIV_OCCURRENCES TBTNIV
	TBTNIV_STATS="${WD}.tbtniv.stats.txt"
	# >> TBTNIV 
	TBTNIV="${WD}tbtniv.txt"

	# extract data from balisep file
	#sed 's/\r//g' "${INPUT}" |
	awk -f build.tbtniv.awk "${INPUT}" | tee "${DATA}" |
		sort -k2,2n -k3,3 | awk '{ print $3 }' | uniq -c |
		tee "${TBTNIV_STATS}" | awk '{ print $2 }' > "${TBTNIV}"
	
	TBTNIV_NR=$(wc -l < "${TBTNIV}")
	BEACON_NR=$(wc -l < "${DATA}")
	# store information in .do_not_modify.txt
	# duplicate/rename source file in ${WD}
	{ cp "${INPUT}" "${WD}BALISEP"; } > /dev/null
	# store variables
	cat > "${WD}.do_not_modify.txt" <<EOF
# DO NOT MODIFY, NE PAS MODIFIER
DATE_CA="${DATE_CA}"
DATE_GEN="${DATE_GEN}"
BEACON_NR="${BEACON_NR}"
TBTNIV_NR="${TBTNIV_NR}"
# ARGUMENTS
SEP_LINES="${SEP_LINES}"
SEP_BLOCKS="${SEP_BLOCKS}"
MAX_BEACONS_PER_LINE="${MAX_BEACONS_PER_LINE}"
WD_PREFIX="${WD_PREFIX}"
EOF

	declare -A ary
	ary[1,"FILE"]="${WD}balisep_tbtniv_balise.txt"
	ary[1,"SORT"]="-k2,2n -k3,3 -k1,1"

	ary[2,"FILE"]="${WD}balisep_nb_tbtniv_balise.txt"
	ary[2,"SORT"]="-k4,4n -k2,2n -k3,3 -k1,1"

	info "  Statistiques: ${TBTNIV_NR} tbtniv, ${BEACON_NR} balise(s)"
	for i in {1..2}; do
	# for i in $(seq 1 $(( ${#ary[@]} / 2 )) ); do
		sort ${ary[$i,"SORT"]} < "${DATA}" | 
			awk -f pr.awk "TBTNIV_NR=${TBTNIV_NR}" \
			"BEACON_NR=${BEACON_NR}" "SEP_LINES=${SEP_LINES}" \
			"SEP_BLOCKS=${SEP_BLOCKS}" "MAXLEN=${MAXLEN}" \
			> "${ary[$i,"FILE"]}"
	done
	info ""
	return 0
}

#if [ -p /dev/stdin ]; then
#	usage 1 "pipe indisponible dans cette version"
#fi

while (($# > 0)); do
	case "$1" in
	-b)
		SEP_BLOCKS=$((!(($SEP_BLOCKS))))
		;;
	-h)
		usage 1
		;;
	-l)
		SEP_LINES=$((!(($SEP_LINES))))
		;;
	-n)
		shift
		if ! [[ $1 =~ ^[0-9]+$ ]]; then
			usage 10 "le champ -n doit être suivi d'un nombre"
		fi
		MAX_BEACONS_PER_LINE=$(($1>0?$1:1))
		;;
	-p)	
		shift
		WD_PREFIX="${1}"
		;;
	*)
		if [ -e "$1" ] && [ -f "$1" ] && is_balisep "$1"; then
			process_balisep "$1"
		else
			usage 11 "champ $1 de type inconnu"
		fi
		;;
	esac
	shift
done

