#!/bin/bash
# $1 is the directory to search in
# $2 is the date limit, what is before - ... is deleted

DIR=./
EPOCH_NOW=$(date +%s)
FORCE=0

function debug {
	return
	# displays $1
	echo "${1}"
} >&2

function usage {
	cat >&2 <<EOF
usage: ./$(basename $0) [-d DIR=./] [-t EPOCH=now] [-f]
Paramètres:
-d DIR    : specifie le repertoire à nettoyer.
-t EPOCH  : précise l'époque en seconde à compter de 01/01/1970,
	    à partir du duquel ne plus effacer les répertoires
            anciennement créées.
            La valeur courante peut s'obtenir avec la commande 'date +%s'
	    conversion d'une date en epoch:
	    	$ date --date="12-feb-12" +%s
	    et l'inverse:
		$ date --date='@2147483647'
-f        : passe outre la vérif d'antériorité. UTILISER AVEC PRECAUTION.

e.g.: ./$(basename $0) -d /tmp -t 1425422800
e.g.: ./$(basename $0) -f
EOF
}

while (( $# > 0 )); do
	case $1 in
	-d)
		shift
		if ! [ -d "${1}" ]; then
			exit 10
		fi
		DIR="${1}"
		;;
	-t)
		shift
		if [ "x${1,,}" == "xnow" ]; then
			debug "now detected"
		elif [[ $1 =~ ^[0-9]+$ ]]; then
			EPOCH_NOW=${1}
		else
			exit 11
		fi
		;;
	-f)
		FORCE=1
		;;
	-h)
		usage
		exit 1
		;;
	esac
	shift
done

function check_dir {
	declare -A files
	files[0]="BALISEP"
	files[1]="balisep_nb_tbtniv_balise.txt"
	files[2]="balisep_tbtniv_balise.txt"
	files[3]="tbtniv.txt"
	files[4]=".data.txt"
	files[5]=".do_not_modify.txt"
	files[6]=".tbtniv.stats.txt"
	files[7]="stats.txt"
	for i in $(seq 0 7); do
		if ! [ -e "${1}${files[$i]}" ]; then
			return 1
		fi
	done
	# no subdirectories
	if [ $(find "${d}" -type d | wc -l) -gt 1 ]; then
		return 1
	fi
	return 0
}

for f in `find "${DIR}" -name ".do_not_modify.txt"`; do
	d="${f%/*}/"
	debug $f
	debug $d
	if ! check_dir "${d}"; then
		continue
	fi
	debug ">> ${d} contient bien les bons fichiers, sans sous-repertoires"
	if ! [[ $d =~ ^(./|/)?(.*/)*(.*_)?[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}h[0-9]{2}_CA[0-9]{4}-[0-9]{2}-[0-9]{2}/$ ]]; then
		continue
	fi
	debug ">> ${d} a un nom valide"
	source "${f}"
	debug "EPOCH_NOW=${EPOCH_NOW}"
	debug "RM_AUTO=${RM_AUTO}"
	if [ ${FORCE} -ne 0 ] || [ ${RM_EPOCH} -lt ${EPOCH_NOW} ]; then
		# debug "rm -Rf \"${d}\""
		echo "\"${d}\" effacé" >&2
		rm -Rf "${d}"
	else
		debug "${d} conservé"
	fi
done
