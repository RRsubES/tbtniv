#!/bin/bash
IFS=$'\n'; for f in `find *.txt ! -type l 2> /dev/null`; do
	rm "$f"
done

IFS=$'\n'; for d in `find . -maxdepth 1 -type d 2> /dev/null | grep '^./[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}_[0-9]\{2\}h[0-9]\{2\}_CA[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}'`; do
	rm -Rf "$d"
done
