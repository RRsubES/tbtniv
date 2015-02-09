# input: BEACON TBTNIV TBTNIV_LEN
# output: BEACON TBTNIV_LEN TBTNIV TBTNIV_OCC(occurences)
BEGIN {
	FS="[ \t]*"
}

{
	# name: $1, layers: $2
	nb[$2][$1]=$3
	count[$2]++
}

END {
	for (l in nb)
		total++
	printf("%d\n", total)
	for (l in nb) {
		for (n in nb[l])
			printf("%s %d %s %d\n", n, nb[l][n], l, count[l])

	}
}
