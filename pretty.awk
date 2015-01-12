# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
BEGIN {
	if (ENVIRON["PRETTY_EXTRAINFO"] == 1)
		printf("Date CA du %s\nLivraison le %s\nClassement [%s]\n\n",
			ENVIRON["DATE_CA"], ENVIRON["DATE_DELIVER"], ENVIRON["PRETTY_SORT"])
	getline # to read first special line and get total nb of tbtniv
	printf("%-5s %-39s %3s\n", "Bal.", 
			sprintf("Tbtniv (%d distinct(s))", $1), "Nb.") 
}

{
	printf("%-5s %-39s %3d\n", $1, $2, $3)
}

END {
	printf(">> tri \"%s\" dans [%s]\n", ENVIRON["PRETTY_SORT"], ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}
