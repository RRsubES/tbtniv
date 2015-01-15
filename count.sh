#!/usr/bin/awk -f

BEGIN {
	getline
}

$2 != prev {
	prev = $2
	count++
}
END {
	printf("nb tbtniv: %d\n", count)
}
