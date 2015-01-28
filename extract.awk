# input: 3 4G 115 SR... or 314G *** PX...
# output: BEACON LVLS_SEPARATED_BY_HYPHEN NUMBER_OF_LVLS
function lvl(l) # returns the number of levels in the template
{
	# length is odd; 3, 7, 11, ... should return 1, 2, 3
	return (length(l) + 1) / 4;
}

{
	# replace first occurence of *** with 999
	sub(/\*\*\*/, "999", $0)

	name = (substr($0, 2, 1) == " " ? $2 : substr($1, 3))

	s=substr($0, 9)
	if (!(name in layers))
		layers[name]="000"
	nb=split(s, ary, "[ \t\n]*")
	for(i = 1; i < nb; i+=2) 
		layers[name]=layers[name] "-" ary[i]
}

END {
	for (n in layers) 
		printf("%s %s %d\n", n, layers[n], lvl(layers[n]))
}

