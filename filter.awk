
# input: filetype is BALISEP
# output: lines with beacons and levels only

BEGIN {
	getline
}

/^3[ 12][A-Z0-9]{2,5} .*$/ { print }
