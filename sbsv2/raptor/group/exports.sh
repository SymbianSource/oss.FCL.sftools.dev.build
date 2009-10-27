#!/bin/bash

# script to generate exports for this component

# copy ../* to /tools/sbs

find .. -maxdepth 1 -type f -not -name "distribution.policy*" -print | sed 's!\.\.\(.*\)!\.\.\1 /tools/sbs\1!' > exports.inf

for i in bin lib python schema util; do
    find ../$i -type f -not -name "distribution.policy*" -not -name "*.pyc" -print | sed 's!\.\.\(.*\)!\.\.\1 /tools/sbs\1!' >> exports.inf
done

