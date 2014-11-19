# input: BEACON LVLS_SEPARATED_BY_HYPHEN NUMBER_OF_LVLS
# output: BEACON NUMBER_OF_LVLS LVLS_SEP_BY_HYPHEN NUMBER_OF_BEACON_USING_THAT_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
BEGIN {
	FS="[ \t]*"
}

{
	name=$1; layers=$2
	db[layers][name]=$3
	count[layers]++
}

END {
	for (t in db) {
		total++
		suffix[t]=sprintf("%s %d", t, count[t])
	}
	for (t in db) {
		for (n in db[t]) 
			printf("%s %d %s %d\n", n, db[t][n], suffix[t], total) 

	}
}
