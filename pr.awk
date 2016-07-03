BEGIN {
	pv_tbtniv = ""
	beacons = ""
	prefix = ""
}

function pr() {
	if (pv_tbtniv == "") {
		printf("%39s %3s %s\n", sprintf("tbtniv(%d)", TBTNIV_NR), "Nb.", sprintf("Balises(%d)", BEACON_NR)) 
		return
	}
	while(length(beacons) > MAXLEN) {
		printf("%43s %s\n", prefix, substr(beacons, 0, MAXLEN - 1))
		beacons = substr(beacons, MAXLEN + 1)
		prefix = sprintf("%39s %3s", ".", ".")
		if (SEP_LINES == "1")
			printf("\n")
	}
	printf("%43s %s\n", prefix, substr(beacons, 0, length(beacons) - 1))
	if (SEP_BLOCKS == "1" || SEP_LINES == "1")
		printf("\n")
	beacons = ""; pv_tbtniv = ""; prefix = ""
}

# beacon tbtniv_size tbtniv tbtniv_occurence
# keep the given order
{
	if (pv_tbtniv != $3) {
		pr()
		pv_tbtniv = $3
		prefix = sprintf("%39s %3d", $3, $4)
	}
	beacons = sprintf("%s%-5s ", beacons, $1)
}

END {
	pr()
}
