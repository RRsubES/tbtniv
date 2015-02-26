BEGIN {
	pv_tbtniv = ""
	pv_tbtniv_nr = ""
	beacons = ""
}

function pr() {
	if (FNR == 1) {
		printf("%39s %3s %s\n", sprintf("tbtniv(%d)", TBTNIV_NR), "Nb.", sprintf("Balises(%d)", BEACON_NR)) 
		return
	}
	header = sprintf("%39s %3d", pv_tbtniv, pv_tbtniv_nr)
	while(length(beacons) > MAXLEN) {
		printf("%43s %s\n", header, substr(beacons, 0, MAXLEN - 1))
		beacons = substr(beacons, MAXLEN + 1)
		header = sprintf("%39s %3s", ".", ".")
		if (EMPTYLINE == "1")
			printf("\n")
	}
	printf("%43s %s\n", header, substr(beacons, 0, length(beacons) - 1))
	if (SPLIT == "1" || EMPTYLINE == "1")
		printf("\n")
	beacons = ""; pv_tbtniv = ""; pv_tbtniv_nr = ""
}

# beacon tbtniv_size tbtniv tbtniv_occurence
# keep the given order
{
	if (pv_tbtniv != $3) {
		pr()
		pv_tbtniv = $3
		pv_tbtniv_nr = $4
	}
	beacons = sprintf("%s%-5s ", beacons, $1)
}

END {
	pr()
}
