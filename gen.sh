#!/bin/bash

function usage {
	# $1 contains the exit error code
	# $2 contains the error msg to display if needed
	if [ ! "x$2" == "x" ]; then
		err "$2"
	fi
	cat >&2 <<EOF
usage: ./$(basename $0) [-a] [-b] [-l] [-d] [-h] [-n NB] [-o DIR] [-p PREFIX] [-q] BALISEP_1 BALISEP_2...
Paramètres:
-a	    : efface le répertoire ${RM_WAIT} secondes après sa génération.
-b	    : sépare chaque bloc de tbtniv par une interligne.
-l    	    : sépare chaque ligne par une interligne.
-d	    : affiche le nom des répertoires créés sur l'entrée standard.
-h	    : affiche l'aide
-n NB=${MAX_BEACONS_PER_LINE}     : spécifie le nombre max de balises affichées par ligne.
-o DIR=./   : change le répertoire destination à DIR (rep courant par défaut).
-f	    : copie par ftp sur le reseau dans le répertoire defini par defaut.
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

function ftp_copy {
	local AR_FILE
	local FTP_CFG
	local LWD
	LWD="$(pwd)"
	LWD="${LWD%/}/"
	AR_FILE="${GEN_DIR}.tar.gz"
	FTP_CFG=./bleiz.cfg
	# FTP_CFG=./free.cfg
	# 4 variables to define, FTP_USER, FTP_PW, FTP_ADR and FTP_DIR
	! [ -e "${FTP_CFG}" ] && err 10 "pas de config ftp disponible"
	source "${FTP_CFG}"
	( cd "${DST_ROOT}"; tar czvf "${LWD}${AR_FILE}" "${GEN_DIR}" ;) > /dev/null 2>&1
	[ $? -ne 0 ] && err 10 "problème à la création du fichier ${AR_FILE}"
	ftp -in ${FTP_ADR}<<EOF
quote user ${FTP_USER}
quote pass ${FTP_PW}
cd "${FTP_DIR}"
binary
put "${AR_FILE}"
quit
EOF
	[ $? -ne 0 ] && err 16 "impossible de copier ${AR_FILE} par ftp"
	rm -f "${LWD}${AR_FILE}"
}

function is_balisep {
	local HEADER='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
	{ head -1 "$1" | sed 's/\r//g' | grep "$HEADER"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "$1 a une entête de fichier non valide." 
		return 1
	fi
	return 0
}

function info {
	[ $QUIET -eq 0 ] && echo "$1"
} >&2

function err {
	# echo "[E]${INFILE:+${INFILE#*/} :} $1"
	echo "[E] $1"
} >&2

# Default values
SEP_LINES=0
SEP_BLOCKS=0
MAX_BEACONS_PER_LINE=5
PREFIX=
DST_ROOT=./
PRINT_DST=0
QUIET=0
RM_WAIT=20
RM_AUTO=0
RM_EPOCH=$(( RM_WAIT + $(date +%s)))
FTP_COPY=0

INFILE=
DATE_GEN=$(date '+%Y-%0m-%0d_%0kh%0M')

function process_balisep {
	# $1 = BALISEP file
	# Set instance values
	INFILE="$1"
	# better to keep DATE_GEN once for the whole instance,
	# much easier to complete filenames...
	MAXLEN=$((6 * MAX_BEACONS_PER_LINE))
	# echo date is DD-MM-YY, changing it to YYYY-MM-DD
	DATE_CA=$(head -1 "${INFILE}" | tr -s ' ' | cut -d' ' -f7 | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
	BEACON_NR=
	TBTNIV_NR=

	info "* ${INFILE}: date CA ${DATE_CA}" 

	# create Working Directory
	GEN_DIR="${PREFIX:+${PREFIX}_}${DATE_GEN}_CA${DATE_CA}"
	DST_DIR="${DST_ROOT}${GEN_DIR}/"
	if [ -e "${DST_DIR}" ]; then
		err "repertoire ${DST_DIR} déjà utilisé, abandon."
		return 10
	fi
	{ mkdir -p "${DST_DIR}"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "impossible de créer le repertoire ${DST_DIR}"
		return 11
	fi
	# does not work in my Cygwin, bash version probly outdated
	info "  Résultats disponibles dans [${DST_DIR}]"

	# >> BEACON TBTNIV_LEN TBTNIV TBTNIV_OCCURRENCES
	DATA="${DST_DIR}.data.txt"
	# >> TBTNIV_OCCURRENCES TBTNIV
	TBTNIV_STATS="${DST_DIR}.tbtniv.stats.txt"
	# >> TBTNIV 
	TBTNIV="${DST_DIR}tbtniv.txt"

	# extract data from balisep file
	#sed 's/\r//g' "${INFILE}" |
	awk -f build.tbtniv.awk "${INFILE}" | tee "${DATA}" |
		sort -k2,2n -k3,3 | awk '{ print $3 }' | uniq -c |
		tee "${TBTNIV_STATS}" | awk '{ print $2 }' > "${TBTNIV}"
	
	TBTNIV_NR=$(wc -l < "${TBTNIV}")
	BEACON_NR=$(wc -l < "${DATA}")
	# store information in ..do_not_modify.txt
	# duplicate/rename source file in ${DST_DIR}
	{ cp "${INFILE}" "${DST_DIR}BALISEP"; } > /dev/null
	# store variables
	cat > "${DST_DIR}.do_not_modify.txt" <<EOF
# DO NOT MODIFY, NE PAS MODIFIER
DATE_CA="${DATE_CA}"
DATE_GEN="${DATE_GEN}"
RM_EPOCH="${RM_EPOCH}"
RM_AUTO="${RM_AUTO}"
BEACON_NR="${BEACON_NR}"
TBTNIV_NR="${TBTNIV_NR}"
FTP_COPY="${FTP_COPY}"
# ARGUMENTS
SEP_LINES="${SEP_LINES}"
SEP_BLOCKS="${SEP_BLOCKS}"
MAX_BEACONS_PER_LINE="${MAX_BEACONS_PER_LINE}"
PREFIX="${PREFIX}"
DST_ROOT="${DST_ROOT}"
GEN_DIR="${GEN_DIR}"
PRINT_DST="${PRINT_DST}"
QUIET="${QUIET}"
EOF
	chmod gu-w "${DST_DIR}.do_not_modify.txt" 

	declare -A ary
	ary[1,"FILE"]="${DST_DIR}balisep_tbtniv_balise.txt"
	ary[1,"SORT"]="-k2,2n -k3,3 -k1,1"

	ary[2,"FILE"]="${DST_DIR}balisep_nb_tbtniv_balise.txt"
	ary[2,"SORT"]="-k4,4n -k2,2n -k3,3 -k1,1"
	echo "Statistiques: ${TBTNIV_NR} tbtniv, ${BEACON_NR} balise(s)." > "${DST_DIR}stats.txt"
	info "  $(cat "${DST_DIR}stats.txt")"

	for i in {1..2}; do
		sort ${ary[$i,"SORT"]} < "${DATA}" | 
			awk -f pr.awk "TBTNIV_NR=${TBTNIV_NR}" \
			"BEACON_NR=${BEACON_NR}" "SEP_LINES=${SEP_LINES}" \
			"SEP_BLOCKS=${SEP_BLOCKS}" "MAXLEN=${MAXLEN}" \
			> "${ary[$i,"FILE"]}"
	done
	info ""
	if [ ${PRINT_DST} -ne 0 ]; then
		echo "${DST_DIR}"
	fi
	[ ${FTP_COPY} -ne 0 ] && ftp_copy
	[ ${RM_AUTO} -ne 0 ] && nohup bash -c "sleep ${RM_WAIT} && rm -Rf \"${DST_DIR}\"" &> /dev/null &
	return 0
}

#if [ -p /dev/stdin ]; then
#	usage 1 "pipe indisponible dans cette version"
#fi

while (($# > 0)); do
	case "$1" in
	-a)
		RM_AUTO=$((!(($RM_AUTO))))
		;;
	-b)
		SEP_BLOCKS=$((!(($SEP_BLOCKS))))
		;;
	-d)	
		PRINT_DST=$((!(($PRINT_DST))))
		;;
	-h)
		usage 1
		;;
	-l)
		SEP_LINES=$((!(($SEP_LINES))))
		;;
	-n)
		shift
		! [[ $1 =~ ^[0-9]+$ ]] && usage 10 "le champ -n doit être suivi d'un nombre"
		MAX_BEACONS_PER_LINE=$(($1>0?$1:1))
		;;
	-o)
		shift
		! [ -d "${1}" ] && usage 11 "${1} n'est pas un répertoire"
		! [ -w "${1}" ] && usage 11 "${USER} n'a pas les droits en écriture sur ${1}"
		DST_ROOT="${1%/}/"
		;;
	-f)
		FTP_COPY=$((!(($FTP_COPY))))
		;;
	-p)	
		shift
		PREFIX="${1// /_}"
		;;
	-q)
		QUIET=$((!(($QUIET))))
		;;
	*)
		! [ -e "$1" ] && usage 11 "$1 n'est pas un fichier existant"
		! [ -f "$1" ] && usage 11 "$1 n'est pas un fichier régulier"
		! is_balisep "$1" && usage 11 "$1 n'est pas un fichier balisep"
		process_balisep "$1"
		;;
	esac
	shift
done

