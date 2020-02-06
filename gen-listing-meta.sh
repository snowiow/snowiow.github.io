#!/bin/bash

echo "posts:" > $1
./post-listing.sh ${@:3} |
sort -r |
head -n $2 |
awk '{print "-\n  date: " $1 "\n  url: " $2; print "  title: " substr($0, index($0,$3)) }' >> $1
