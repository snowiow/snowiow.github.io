#!/bin/bash

for filename in "${@:1}"
do
    path=$(echo $filename | cut -d '/' -f2- | sed -E 's/\.md$/.html/g')
    title=$(grep 'title:' $filename | cut -d ' ' -f2-)
    date=$(grep 'date:' $filename | cut -d ' ' -f2)
    echo "$date $path $title"
done
