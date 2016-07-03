# extract tbtniv from BALISEP, display it how it arrived but with stats
function lvl(t) {
	return (length(t) + 1) / 4
}

function store(b, t) {
	if (b == "" || t == GROUND)
		return
	# if sort is used, the order gonna differ
	# numbers appear at the end here...
	beacon[beacon_nr++] = b
	tbtniv_nr[t]++
	tbtniv[b] = t
}

BEGIN {
	#ignore first line
	getline
	GROUND = "000"
	prev_tbtniv = GROUND
	prev_beacon = ""
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
	for(i = 0; i < beacon_nr; i++) {
		b = beacon[i]; t = tbtniv[b]
		print b, lvl(t), t, tbtniv_nr[t]
	}
}
