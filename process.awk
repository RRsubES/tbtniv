# input: BEACON LVLS_SEPARATED_BY_HYPHEN NUMBER_OF_LVLS
# output: BEACON NUMBER_OF_LVLS LVLS_SEP_BY_HYPHEN NUMBER_OF_BEACON_USING_THAT_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
BEGIN {
	FS="[ \t]*"
}

{
	name=$1; layers=$2
	nb[layers][name]=$3
	count[layers]++
}

END {
	for (t in nb) {
		total++
		t_count[t]=sprintf("%s %d", t, count[t])
	}
	for (t in nb) {
		for (n in nb[t]) 
			printf("%s %d %s %d %d\n", n, nb[t][n], t_count[t], total) 

	}
}
