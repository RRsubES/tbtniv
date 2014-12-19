
# input: filetype is BALISEP
# output: lines with beacons and levels only
# replace "***"  with "999"
# header is skipped in bash calling file
/^3[ 12][A-Z0-9]{2,5} .*$/ { 
	sub(/\*\*\*/, "999", $0)
	print
}
