#!/bin/bash
#syntax: ./$(basename $0) ./DIR1 ./DIR2
#./DIR1 et ./DIR2 are created with gen.sh.

function check_gen_dir {
	# $1 has no trailing /
	if [ ! -e "$1" ] || [ ! -d "$1" ] ; then
		echo "Répertoire $1 non valide" >&2
		exit 1
	fi
	check_file "${1}/.do_not_modify.txt"
	check_file "${1}/tbtniv.txt"
}

function check_file {
	if [ ! -e "$1" ] || [ ! -f "$1" ] ; then
		echo "Fichier $1 non trouvé" >&2
		exit 2
	fi
}

declare -A DB
for i in $(seq 1 2); do
	DIR="${1%/}"
	check_gen_dir "${DIR}"
	source "${DIR}/.do_not_modify.txt"
	DB[$i,"DIR"]="${DIR}"
	DB[$i,"CA"]="${DATE_CA?\$DATE_CA indéfinie, repertoire non valide}"
	DB[$i,"FILE"]="${DIR}/tbtniv.txt"
	shift
done

DST="diff.CA${DB[1,"CA"]}.CA${DB[2,"CA"]}.txt"

echo "Delta entre les bandes CA du ${DB[1,"CA"]} et ${DB[2,"CA"]}" > "${DST}"
diff -u0 "${DB[1,"FILE"]}" "${DB[2,"FILE"]}" |
	grep "^[+-][^+-].*" |
	awk '{print substr($0,0,1), length(substr($0,2)), substr($0,2)}' |
	sort -k1,1 -k2,2n -k3,3 |
	awk '
/^-.*/ {
	del[del_nr++] = $3;
}

/^\+.*/ {
	add[add_nr++] = $3;
}

END {
	printf("%39s%2s%-39s\n", sprintf("Créés(%d)", add_nr), "", sprintf("Supprimés(%d)", del_nr));
	for(i=0; i < (del_nr > add_nr ? del_nr : add_nr); i++)
		printf("%39s%2s%-39s\n", add[i], "", del[i]);
}' >> "${DST}"

echo "Le résultat se trouve dans ${DST}"
# it is possible to convert from UTF8 to latin1 (windows)
# use iconv -l to get the list of available charset
# iconv -f UTF-8 -t latin1 INPUT_FILE > OUTPUT_FILE

