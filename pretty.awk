# input: (sorted) BEACON TBTNIV_LEN TBTNIV TBTNIV_OCC(occurences)
# output:
BEGIN {
	printf("%39s %-3s %s\n", sprintf("Tbtniv(%d)", ENVIRON["PRETTY_NR_TBTNIV"]), "Nb.", "Balises")
	pv_tbtniv = ""
	beacons = ""
	header = ""
}

function pr() {
	if (header == "" || beacons == "")
		return
	while(length(beacons) > ENVIRON["PRETTY_MAXLEN"]) {
		printf("%43s %s\n", header, substr(beacons, 0, ENVIRON["PRETTY_MAXLEN"] - 1))
		beacons = substr(beacons, ENVIRON["PRETTY_MAXLEN"] + 1)
		header = sprintf("%39s %3s", "", "")
		if (ENVIRON["PRETTY_EMPTYLINE"] == "1")
			printf("\n")
	}
	printf("%43s %s\n", header, substr(beacons, 0, length(beacons) - 1))
	if (ENVIRON["PRETTY_SPLIT"] == "1" || ENVIRON["PRETTY_EMPTYLINE"] =="1")
		printf("\n")
	beacons = ""
	header = ""
}

function beacon_add(bcn) {
	beacons = beacons sprintf("%-5s ", bcn)
}

pv_tbtniv == $2 {
	beacon_add($1)
	next
}

{
	pr()

	pv_tbtniv = $2
	beacon_add($1)
	header = sprintf("%39s %3d", $2, $3)
}

END {
	pr()
	printf(">> tri \"%s\" dans [%s]\n", ENVIRON["PRETTY_SORT"], ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}
