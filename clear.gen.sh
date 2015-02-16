#!/bin/bash
IFS=$'\n'; for f in `find *.txt ! -type l`; do
	rm "$f"
done

IFS=$'\n'; for d in `find . -maxdepth 1 -type d | grep '^./[0-9]\{1,5\}\.[0-9]\{2\}.*\.[0-9]\{4\}-[0-9]\{2\}h[0-9]\{2\}'`; do
	rm -Rf "$d"
done
