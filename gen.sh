!/bin/bash

function usage {
	# $1 contains the error msg to display if needed
	if [ ! "x$1" == "x" ]; then
		err "$1"
	fi
	cat >&2 <<EOF
usage: ./$(basename $0) [-a] [-b] [-l] [-d] [-h] [-n NB] [-o DIR] [-p PREFIX] [-q] BALISEP_1 BALISEP_2...
Parametres:
-a	    : efface le repertoire ${RM_WAIT} secondes apres sa generation.
-b	    : separe chaque bloc de tbtniv par une interligne.
-l    	    : separe chaque ligne par une interligne.
-d	    : affiche le nom des repertoires crees sur l'entree standard.
-h	    : affiche l'aide
-n NB=${MAX_BEACONS_PER_LINE}     : specifie le nombre max de balises affichees par ligne.
-o DIR=./   : change le repertoire destination pour DIR (rep courant par defaut).
-f	    : copie par ftp sur le reseau dans le repertoire defini par defaut.
-p PREFIX   : ajoute PREFIX au nom du repertoire (espaces remplacees par _).
-q	    : mode silencieux.
BALISEP_N   : specifie le nom du ou des fichier(s) pour traitement.

Les fichiers seront generes dans le chemin precise par -o, dans un repertoire
	au nom de: {PREFIX_}{DATE_HEURE_DU_JOUR}_CA{DATE_CA}.

e.g.: ./$(basename $0) -b -l -n 10 BALISEP.15fev -n 15 -p ibp BALISEP.15mar 
e.g.: ./$(basename $0) -p "ibp rr" BALISEP.15mar -p "" BALISEP.15fev
e.g.: ./$(basename $0) -o /tmp -a -b -d -q BALISEP.15mar
EOF
}

function die {
	# $1 is the error code
	# $2 contains the error msg
	usage "$2"
	exit $1
}

function gz2ftp {
	# $1 is the ftp config file
	local GZ_FILE
	local LWD
	LWD="$(pwd)"; LWD="${LWD%/}/"
	GZ_FILE="${GEN_DIR}.tar.gz"
	# 4 variables to define, FTP_USER, FTP_PW, FTP_ADR and FTP_DIR
	! [ -e "${1}" ] && err 10 "pas de config ftp disponible, $1"
	source "${1}"
	{ tar -czvf "${LWD}${GZ_FILE}" -C "${DST_ROOT}" "${GEN_DIR}" ;} > /dev/null 2>&1
	[ $? -ne 0 ] && err 10 "probleme pour creer le fichier ${GZ_FILE}"
	ftp -in ${FTP_ADR}<<EOF
quote user ${FTP_USER}
quote pass ${FTP_PW}
cd "${FTP_DIR}"
binary
put "${GZ_FILE}"
quit
EOF
	[ $? -ne 0 ] && err 16 "impossible de copier ${GZ_FILE} par ftp"
	rm -f "${LWD}${GZ_FILE}"
}

function is_balisep {
	local HEADER='^FORMAT : STIP [ ]*VERSION CA : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*LIVRAISON : [ 0-9]\{1,2\}-[ 0-9]\{1,2\}-[0-9]\{2\} [ ]*PART : BALISEP[ ]*$'
	{ head -1 "$1" | sed 's/\r//g' | grep "$HEADER"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "$1 a une entete de fichier non valide." 
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
RM_WAIT=30
RM_AUTO=0
RM_EPOCH=$(( RM_WAIT + $(date +%s)))
FTP_COPY=0

INFILE=
FILE_NR=0
# better to keep DATE_GEN once for all given files,
# much easier to complete filenames afterwards.
DATE_GEN=$(date '+%Y-%0m-%0d_%0kh%0M')

function process_balisep {
	# $1 = BALISEP file
	# Set instance values
	INFILE="$1"
	MAXLEN=$((6 * MAX_BEACONS_PER_LINE))
	# date is DD-MM-YY, changing it to YYYY-MM-DD
	DATE_CA=$(head -1 "${INFILE}" | tr -s ' ' | cut -d' ' -f7 | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
	! [[ ${DATE_CA} =~ ^20[0-9]{2}-(0[1-9]|10|11|12)-([0-2][1-9]|10|20|30|31)$ ]] && err "DATE_CA non valide, ${DATE_CA}" && return 10
	BEACON_NR=
	TBTNIV_NR=

	info "* ${INFILE}: date CA ${DATE_CA}" 

	# create Working Directory
	GEN_DIR="${PREFIX:+${PREFIX}_}${DATE_GEN}_CA${DATE_CA}"
	DST_DIR="${DST_ROOT}${GEN_DIR}/"
	if [ -e "${DST_DIR}" ]; then
		err "repertoire ${DST_DIR} deja utilise, abandon."
		return 11
	fi
	{ mkdir -p "${DST_DIR}"; } > /dev/null
	if [ $? -ne 0 ]; then
		err "impossible de creer le repertoire ${DST_DIR}"
		return 12
	fi
	info "  Resultats disponibles dans [${DST_DIR}]"

	# >> BEACON TBTNIV_LEN TBTNIV TBTNIV_OCCURRENCES
	DATA="${DST_DIR}.data.txt"
	# >> TBTNIV_OCCURRENCES TBTNIV
	TBTNIV_STATS="${DST_DIR}.tbtniv.stats.txt"
	# >> TBTNIV 
	TBTNIV="${DST_DIR}tbtniv.txt"

	# extract data from balisep file
	awk -f build.tbtniv.awk "${INFILE}" | tee "${DATA}" |
		sort -k2,2n -k3,3 | awk '{ print $3 }' | uniq -c |
		tee "${TBTNIV_STATS}" | awk '{ print $2 }' > "${TBTNIV}"
	
	TBTNIV_NR=$(wc -l < "${TBTNIV}")
	BEACON_NR=$(wc -l < "${DATA}")
	# store information in .do_not_modify.txt
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
	[ ${FTP_COPY} -ne 0 ] && gz2ftp ./bleiz.cfg
	# [ ${FTP_COPY} -ne 0 ] && gz2ftp ./free.cfg
	[ ${RM_AUTO} -ne 0 ] && nohup bash -c "sleep ${RM_WAIT} && rm -Rf \"${DST_DIR}\"" &> /dev/null &
	return 0
}

if [ -p /dev/stdin ]; then
	die 1 "pipe indisponible dans cette version"
fi

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
		die 1
		;;
	-l)
		SEP_LINES=$((!(($SEP_LINES))))
		;;
	-n)
		shift
		! [[ $1 =~ ^[0-9]+$ ]] && die 10 "le champ -n doit etre suivi d'un nombre"
		MAX_BEACONS_PER_LINE=$(($1>0?$1:1))
		;;
	-o)
		shift
		! [ -d "${1}" ] && die 11 "${1} n'est pas un repertoire"
		! [ -w "${1}" ] && die 11 "${USER} n'a pas les droits en ecriture sur ${1}"
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
		! [ -e "$1" ] && die 11 "$1 n'est pas un fichier existant"
		! [ -f "$1" ] && die 11 "$1 n'est pas un fichier regulier"
		! is_balisep "$1" && die 11 "$1 n'est pas un fichier balisep"
		process_balisep "$1"
		FILE_NR=$((FILE_NR + 1))
		;;
	esac
	shift
done

[ ${FILE_NR} -eq 0 ] && die 1 "aucun nom de fichier detecte"
