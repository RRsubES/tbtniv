#!/usr/bin/awk -f
# counts the nb of distinct tbtniv
# ./count.sh < BALISEP.jan15 | sort | uniq | wc -l
# to show stats about tbtniv, sorted...
# ./count.sh < BALISEP.jan15 | sort -k2,2n | uniq -c | sort -k1,1n
function lvl(t) {
	return (length(t) + 1) / 4
}

function echo(p) {
	printf("%3d %s\n", lvl(p), p) | "sort -k1,1n -k2,2 | uniq -c"
}

BEGIN {
	#ignore first line
	getline
	GROUND = "000"
	prev = GROUND
}

/^1 [A-Z0-9]{2,5} .*$/ {
	if (prev != GROUND) {
		echo(prev)
		prev = GROUND
	}
	next
}

/^3[ 12][A-Z0-9]{2,5} .*$/ {
	sub(/\*\*\*/, "999", $0)
	# is the pattern like 31AB or 3 AB, how to start...
	for(i = (substr($0, 2, 1) == " " ? 3 : 2); i < NF; i+=2)
		prev = prev "-" $i
}

END {
	echo(prev)
}
