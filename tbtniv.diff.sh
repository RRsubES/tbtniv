DIR1="${1%/}"
CA1="${DIR1#.*CA}"
#CA1=$(echo ${DIR1#.*CA} | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
FILE1="${DIR1}/tbtniv.txt"

DIR2="${2%/}"
CA2="${DIR2#.*CA}"
#CA2=$(echo ${DIR2#.*CA} | sed -n -e "s_\(..\)-\(..\)-\(..\)_20\3-\2-\1_p")
FILE2="${DIR2}/tbtniv.txt"

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

echo "le résultat se trouve dans ${DST}"
