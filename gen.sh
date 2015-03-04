#!/bin/bash

function usage {
	# $1 contains the exit error code
	# $2 contains the error msg to display if needed
	if [ ! "x$2" == "x" ]; then
		err "$2"
	fi
	cat >&2 <<EOF
usage: ./$(basename $0) [-a] [-b] [-l] [-d] [-h] [-n NB] [-p PREFIX] [-q] BALISEP_1 BALISEP_2...
Paramètres:
-a	    : efface le répertoire ${RM_WAIT} secondes après sa génération.
-b	    : sépare chaque bloc de tbtniv par une interligne.
-l    	    : sépare chaque ligne par une interligne.
-d	    : affiche le nom des répertoires créés sur l'entrée standard.
-h	    : affiche l'aide
-n NB=${MAX_BEACONS_PER_LINE}     : spécifie le nombre max de balises affichées par ligne.
-o DIR=./   : change le répertoire destination à DIR (rep courant par défaut).
-p PREFIX   : ajoute PREFIX au nom du répertoire (espaces remplacées par _).
-q	    : mode silencieux.
BALISEP_N   : spécifie le nom du ou des fichier(s) à traiter.

Les fichiers seront générés dans le chemin précisé par -o, dans un répertoire
	au nom de: {PREFIX_}{DATE_HEURE_DU_JOUR}_CA{DATE_CA}.

e.g.: ./$(basename $0) -b -l -n 10 BALISEP.15fev -n 15 -p ibp BALISEP.15mar 
e.g.: ./$(basename $0) -p "ibp rr" BALISEP.15mar -p "" BALISEP.15fev
e.g.: ./$(basename $0) -o /tmp -a -b -d -q BALISEP.15mar
EOF
	exit $1
}

function is_balisep {
	local HEADER='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
	{ head -1 "$1" | sed 's/\r//g' | grep "$HEADER"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "entête de fichier non valide, forme retenue:" 
		# err "$(echo ${HEADER:1:-2} | sed 's/\\//g')"
		err "$(echo ${HEADER:1:${#HEADER}-3} | sed 's/\\//g')"
		return 1
	fi
	return 0
}

function info {
	[ $QUIET -eq 0 ] && echo "$1"
} >&2

function err {
	echo "[E]${INPUT:+${INPUT#*/} :} $1"
} >&2

# Default values
SEP_LINES=0
SEP_BLOCKS=0
MAX_BEACONS_PER_LINE=5
WD_PREFIX=
WD_ROOT=./
PRINT_WD=0
QUIET=0
RM_WAIT=20
RM_AUTO=0
RM_EPOCH=$(( RM_WAIT + $(date +%s)))

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
	WD="${WD_ROOT}${WD_PREFIX:+${WD_PREFIX}_}${DATE_GEN}_CA${DATE_CA}/"
	if [ -e "${WD}" ]; then
		err "repertoire ${WD} déjà utilisé, abandon."
		return 10
	fi
	{ mkdir -p "${WD}"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "impossible de créer le repertoire ${WD}"
		return 11
	fi
	# does not work in my Cygwin, bash version probly outdated
	info "  Résultats disponibles dans [${WD}]"

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
RM_EPOCH="${RM_EPOCH}"
RM_AUTO="${RM_AUTO}"
BEACON_NR="${BEACON_NR}"
TBTNIV_NR="${TBTNIV_NR}"
# ARGUMENTS
SEP_LINES="${SEP_LINES}"
SEP_BLOCKS="${SEP_BLOCKS}"
MAX_BEACONS_PER_LINE="${MAX_BEACONS_PER_LINE}"
WD_PREFIX="${WD_PREFIX}"
WD_ROOT="${WD_ROOT}"
PRINT_WD="${PRINT_WD}"
QUIET="${QUIET}"
EOF
	chmod gu-w "${WD}.do_not_modify.txt" 

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
	if [ ${PRINT_WD} -ne 0 ]; then
		echo "${WD}"
	fi
	[ ${RM_AUTO} -ne 0 ] && nohup bash -c "sleep ${RM_WAIT} && rm -Rf \"${WD}\"" &> /dev/null &
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
	-d)	
		PRINT_WD=$((!(($PRINT_WD))))
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
	-o)
		shift
		! [ -d "${1}" ] && usage 11 "${1} n'est pas un répertoire"
		! [ -w "${1}" ] && usage 11 "${USER} n'a pas les droits en écriture dans ${1}"
		WD_ROOT="${1%/}/"
		;;
	-p)	
		shift
		WD_PREFIX="${1// /_}"
		;;
	-q)
		QUIET=$((!(($QUIET))))
		;;
	-a)
		RM_AUTO=$((!(($RM_AUTO))))
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

