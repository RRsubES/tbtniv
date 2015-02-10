# input: (sorted) BEACON TBTNIV_LEN TBTNIV TBTNIV_OCC(occurences)
# output:
BEGIN {
	printf("%39s %-3s %s\n", sprintf("Tbtniv(%d)", ENVIRON["PRETTY_NR_TBTNIV"]), "Nb.", "Balises")
	pv_tbtniv = ""
	beacons = ""
	header = ""
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
	if (length(beacons) + length(sprintf("%6s", $1)) > ENVIRON["PRETTY_MAXLEN"]) {
		pr(header, beacons)
		beacons = ""; beacon_add($1)
		header = sprintf("%39s %3s", "", "")
	} else
		beacon_add($1)
	next
}

{
	pr(header, beacons)
	if (NR > 1 && ENVIRON["PRETTY_SPLIT"] == "1" && ENVIRON["PRETTY_EMPTYLINE"] =="0")
		printf("\n")

	pv_tbtniv = $2
	beacons = ""; beacon_add($1)
	header = sprintf("%39s %3d", $2, $3)
}

END {
	pr(header, beacons)
	printf(">> tri \"%s\" dans [%s]\n", ENVIRON["PRETTY_SORT"], ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}
