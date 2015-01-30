#!/usr/bin/awk -f
# counts the nb of distinct tbtniv
function store(t, b) {
	if (db[t] == "")
		total++
	db[t] = db[t] "" sprintf("%-6s", b)
}

function lvl(t) {
	return (length(t) + 1) / 4;
}

function occ(t) {
	return length(db[t]) / 6;
}

function echo(h, s) {
	printf("%48s %s\n", h, s) | "sort -k3,3n -k1,1n -k2,2 | awk '{ print substr($0, 6) }'"
}

BEGIN {
	#ignore first line
	getline
	GROUND = "000"
	prev_tbtniv = GROUND
	NBEACON = 6
	NBLEN = NBEACON * 6
}

/^1 [A-Z0-9]{2,5} .*$/ {
	if (prev_tbtniv != GROUND) {
		store(prev_tbtniv, beacon)
		prev_tbtniv = GROUND
	}
	beacon = $2
	next
}

/^3[ 12][A-Z0-9]{2,5} .*$/ {
	sub(/\*\*\*/, "999", $0)
	#skip "3[ 12]TERPO "
	$0 = substr($0, 9)
	for(i = 1; i < NF; i+=2)
		prev_tbtniv = prev_tbtniv "-" $i
}

END {
	store(prev_tbtniv, beacon)
	printf("%39s %3s %-10s\n", sprintf("%d tbtniv", total), "#", "balises...")
	for (t in db) {
		#l = length(db[t])
		#header = sprintf("%3d %39s %3d", lvl(t), t, occ(t))
		#while (l > NBLEN) {
		#	echo(header, substr(db[t], 0, NBLEN - 1))
		#	db[t] = substr(db[t], NBLEN + 1)
		#	l -= NBLEN
		#	header = ""
		#}
		#echo(header, substr(db[t], 0, length(db[t]) - 1))
		header = sprintf("%3d %39s %3d", lvl(t), t, occ(t))
		echo(header, db[t])
	}
}
