BEGIN {
	getline; print $0
	NBEACON = 9
	NBLEN = NBEACON * 6
	LHEADER = 43
}

{
	header = substr($0, 0, LHEADER)
	$0 = substr($0, LHEADER + 2)
	l = length($0)
	while(l > NBLEN) {
		printf("%43s %s\n", header, substr($0, 0, NBLEN - 1))
		$0 = substr($0, NBLEN + 1)
		l -= NBLEN
		header = ""
	}
	printf("%43s %s\n", header, $0)
}
