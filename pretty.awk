# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
BEGIN {
	if (ENVIRON["PRETTY_EXTRAINFO"] == 1)
		printf("Date CA du %s\nLivraison le %s\nClassement [%s]\n\n",
			ENVIRON["DATE_CA"], ENVIRON["DATE_DELIVER"], ENVIRON["PRETTY_SORT"])
	getline # to read first special line and get total nb of tbtniv
	printf("%39s %-3s %s\n", sprintf("Tbtniv (%d distinct(s))", $1), "Nb.", "Balises")
	pv_tbtniv = ""
	beacons = ""
	header = ""
	MAXLEN = ENVIRON["PRETTY_MAXLEN"]
}

function pr(hdr, bcns) {
	if (hdr == "" && bcns == "")
		return
	printf("%43s %s\n", hdr, substr(bcns, 0, length(bcns) - 1))
	if (ENVIRON["PRETTY_EMPTYLINE"])
		printf("\n")
}

function beacon_add(bcn) {
	beacons = beacons sprintf("%-5s ", bcn)
}

pv_tbtniv == $2 {
	if (length(beacons) >= MAXLEN) {
		pr(header, beacons)
		beacons = ""; beacon_add($1)
		header = sprintf("%39s %3s", "\"", "\"")
	} else
		beacon_add($1)
	next
}

{
	pr(header, beacons)
	if (NR > 2 && ENVIRON["PRETTY_SPLIT"] == "1" && ENVIRON["PRETTY_EMPTYLINE"] =="0")
		printf("\n")

	pv_tbtniv = $2
	beacons = ""; beacon_add($1)
	header = sprintf("%39s %3d", $2, $3)
}

END {
	pr(header, beacons)
	printf(">> tri \"%s\" dans [%s]\n", ENVIRON["PRETTY_SORT"], ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}
