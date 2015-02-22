#!/bin/bash

# $1 and $2 are files generated with new.sh
# need to delete first field in each line
FILE1="$1.clean"
FILE2="$2.clean"

awk '{print $2 }' "$1" > "${FILE1}"
awk '{print $2 }' "$2" > "${FILE2}"
##
#awk '{print $2 | "sort" }' "$1" > "${FILE1}"
#awk '{print $2 | "sort" }' "$2" > "${FILE2}"
##
#diff -y "${FILE1}" "${FILE2}" 
#comm -13 --nocheck-order --output-delimiter="                              " "${FILE1}" "${FILE2}"
comm -13 --nocheck-order "${FILE1}" "${FILE2}"
#sdiff -dl "${FILE1}" "${FILE2}"
#vimdiff "${FILE1}" "${FILE2}"
#diff -y -W250 "${FILE1}" "${FILE2}" | expand | grep -E -C3 '^.{123} [|<>]( |$)' | colordiff | less -rS
