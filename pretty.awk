# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
function mult(c, n)
{
	l = 1
	s = c
	while (2*l <= n) {
		s = s "" s
		l*=2
	}
	n-=l
	while (n > 0) {
		if (l <= n) {
			s = s "" substr(s, 0, l)
			n-=l
		}
		l/=2
	}
	return s
}

BEGIN {
	printf("TBTNIV au %s, classement [%s]\n%s\n", ENVIRON["DATE_CA"], ENVIRON["PRETTY_SORT"], mult("-", 53))
	printf("%-5s %-39s %3s %3s\n", "Bal.", "Tbtniv", "Nb.", "Tot") 
}

{
	printf("%-5s %-39s %3d %3d\n", $1, $2, $3, $4)
}

END {
	printf(">> tri \"%s\" dans [%s]\n", ENVIRON["PRETTY_SORT"], ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}
