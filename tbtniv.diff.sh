#!/bin/bash
#syntax: ./$(basename $0) ./DIR1 ./DIR2
#./DIR1 et ./DIR2 are created with gen.sh.

function check_dir {
	if [ ! -e "$1" ] || [ ! -d "$1" ] ; then
		echo "Répertoire $1 non valide" >&2
		exit 1
	fi
}

function check_file {
	if [ ! -e "$1" ] || [ ! -f "$1" ] ; then
		echo "Fichier $1 non trouvé" >&2
		exit 2
	fi
}

check_dir "$1"
check_dir "$2"

DIR1="${1%/}"
CA1="${DIR1#*CA}"
FILE1="${DIR1}/tbtniv.txt"

DIR2="${2%/}"
CA2="${DIR2#*CA}"
FILE2="${DIR2}/tbtniv.txt"

check_file "${FILE1}"
check_file "${FILE2}"

DST="diff.CA${CA1}.CA${CA2}.txt"

echo "Delta entre les bandes CA du ${CA1} et ${CA2}" > "${DST}"
diff -u0 "${FILE1}" "${FILE2}" |
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
