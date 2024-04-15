#!/bin/sh

for file in *.nii.gz; do
 gzip -t "$file" && echo "$file" >> ok.txt || { echo "$file" >> broken.txt; }
done
