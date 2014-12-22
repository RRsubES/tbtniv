# input: 3 4G 115 SR... or 314G *** PX...
# output: BEACON LVLS_SEPARATED_BY_HYPHEN NUMBER_OF_LVLS
{
	# replace first occurence of *** with 999
	sub(/\*\*\*/, "999", $0)

	if (substr($0, 2, 1) == " ")
		name=$2
	else
		name=substr($1,3)

	s=substr($0, 9)
	if (!(name in count)) {
		count[name]++
		layers[name]="000"
	}
	nb=split(s, ary, "[ \t\n]*")
	for(i = 1; i < nb; i+=2) {
		layers[name]=layers[name] "-" ary[i]
		count[name]++
	}
}

END {
	for (n in count) 
		printf("%s %s %d\n", n, layers[n], count[n])
}

