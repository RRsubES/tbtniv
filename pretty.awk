# input: (sorted) BEACON TBTNIV NUMBER_OF_BEACONS_USING_THIS_TBTNIV TOTAL_NUMBER_OF_DIFFERENT_TBTNIV
# output:
BEGIN {
	printf("%-5s %-39s %3s %3s\n", "Bal.", "TBTNIV", "Nb.", "Tot") 
}

{
	printf("%-5s %-39s %3d %3d\n", $1, $2, $3, $4)
}

END {
	#print "> [" ENVIRON["OUTPUT_FILE"] "]: OK" > "/dev/stderr"
	printf("> [%s]: OK\n", ENVIRON["PRETTY_FILE"]) > "/dev/stderr"
}