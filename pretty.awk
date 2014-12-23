# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
function multpow2(c, order)
{
	s = c
	for(i = 0; i < order; i++)
		s = s "" s
	return s
}

function mult(c, n)
{
	pm = int(log(n)/log(2))
	o = pm
	p = 2**pm
	s = ""
	while(p >= 1) {
		if (p <= n) {
			s = s "" multpow2(c, o)
			n = n - p
		}
		o--
		p=p/2
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
