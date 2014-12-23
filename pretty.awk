# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
function mult(c, n)
{
	if (n > 1) {
		if (n % 2 == 1)
			return c""mult(c,n-1)
		s = mult(c, n/2)
		return s""s
	}
	return (n == 1) ? c : ""
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
