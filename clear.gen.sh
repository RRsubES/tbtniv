#!/bin/bash
IFS=$'\n'; for f in `find *.txt ! -type l`; do
	rm "$f"
done
