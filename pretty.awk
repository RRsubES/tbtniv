# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
function mult(c, n)
{
	# n > 0 
	l = 1
	s = c
	while (2*l <= n) {
		s = s "" s
		l*=2
	}
	n-=l
	if (n > 0)
		s = s "" substr(s, 0, n)
	return s
}

BEGIN {
	if (ENVIRON["PRETTY_EXTRAINFO"] == 1)
		printf("Date CA du %s\nLivraison le %s\nClassement [%s]\n\n",
			ENVIRON["DATE_CA"], ENVIRON["DATE_DELIVER"], ENVIRON["PRETTY_SORT"])
	printf("%-5s %-39s %3s %3s\n", "Bal.", "Tbtniv", "Nb.", "Tot") 
	if (ENVIRON["PRETTY_EXTRAINFO"] == 1)
		printf("%s\n", mult("-", 53)) 
}

{
	printf("%-5s %-39s %3d %3d\n", $1, $2, $3, $4)
}

END {
	printf(">> tri \"%s\" dans [%s]\n", ENVIRON["PRETTY_SORT"], ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}
