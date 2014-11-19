#!/bin/bash

# gen.sh < input > output
awk -f filter.awk | 
 awk -f extract.awk |
 awk -f process.awk |
 awk -f pretty.awk

