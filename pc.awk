# INIT = 1

BEGIN {
	pv_tbtniv = ""
	beacons = ""
	MAXLEN = 6 * 12
	EMPTYLINE = 0
	SPLIT = 1
#print "launching..."
}

function pr() {
	if (pv_tbtniv == "")
		return
	if (beacons_count > 0) {
		printf("%39s %3s %s\n", sprintf("tbtniv(%d)", tbtniv_count), "Nb.", sprintf("Balises(%d)", beacons_count)) 
		beacons_count = 0
	}
	header = sprintf("%39s %3d", pv_tbtniv, tbtniv_stats[pv_tbtniv])
	while(length(beacons) > MAXLEN) {
		printf("%43s %s\n", header, substr(beacons, 0, MAXLEN - 1))
		beacons = substr(beacons, MAXLEN + 1)
		header = sprintf("%39s %3s", ".", ".")
		if (EMPTYLINE == "1")
			printf("\n")
	}
	printf("%43s %s\n", header, substr(beacons, 0, length(beacons) - 1))
	if (SPLIT == "1" || EMPTYLINE =="1")
		printf("\n")
	beacons = ""; pv_tbtniv = ""
}

# tbtniv...
INIT == 1 {
#	print "INIT=1", $1, " detected"
	if (tbtniv_stats[$1] == 0)
		tbtniv_count++
	tbtniv_stats[$1]++
	beacons_count++
#print $1, tbtniv_stats[$1]
}

# beacon tbtniv_size tbtniv...
# keep the given order
INIT == 0 {
#	print "INIT=0", $1, " detected"
#print ">> ", $1, $2, $3, pv_tbtniv
	if (pv_tbtniv == $3) {
		beacons = sprintf("%s%-5s ", beacons, $1)
	} else {
		pr()
		beacons = sprintf("%-5s ", $1)
		pv_tbtniv = $3
	}
}

END {
	pr()
}
