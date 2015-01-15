#!/usr/bin/awk -f
# ./check.sh < BALISEP.jan15 | sort | uniq | wc -l

BEGIN {
	getline
	GROUND = "000"
	prev = GROUND
}

/^1 [A-Z0-9]{2,5} .*$/ {
	if (prev != GROUND)
		print prev
	prev = GROUND
	next
}

/^3[ 12][A-Z0-9]{2,5} .*$/ {
	sub(/\*\*\*/, "999", $0)
#print $0
	if (substr($0, 2, 1) == " ") 
		start = 3
	else
		start = 2
	for(i=start; i < NF; i+=2)
		prev = prev "-" $i
}

END {
	if (prev != GROUND) 
		print prev

}
