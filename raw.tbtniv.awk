# extract tbtniv from BALISEP, display it sorted with stats
function lvl(t) {
	return (length(t) + 1) / 4
}

function store(b, p) {
	if (b == "" || p == GROUND)
		return
	tbtniv[p]++
	db[b] = p
}

BEGIN {
	#ignore first line
	getline
	GROUND = "000"
	prev_tbtniv = GROUND
	prev_beacon = ""
	tbtniv_count = 0
	beacons_nr = 0
}

/^1 [A-Z0-9]{2,5} .*$/ {
	store(prev_beacon, prev_tbtniv)
	prev_tbtniv = GROUND
	prev_beacon = $2
	next
}

/^3[ 12][A-Z0-9]{2,5} .*$/ {
	sub(/\*\*\*/, "999", $0)
	# is the pattern like 31AB or 3 AB, how to start...
	start = (substr($0, 2, 1) == " " ? 3 : 2)
	for(i = start; i < NF; i+=2)
		prev_tbtniv = prev_tbtniv "-" $i
}

END {
	store(prev_beacon, prev_tbtniv)
	for (b in db)
		print b, lvl(db[b]), db[b], tbtniv[db[b]]
}
