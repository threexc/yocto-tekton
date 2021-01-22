#!/bin/bash

LAYERDIR="meta-openembedded"
SUBGROUP="python"

echo "Fetching list of ptests"
PTEST_LIST="$(cd $LAYERDIR && grep -r "ptest" meta-${SUBGROUP} | awk -F'/' '{print $4}' | awk -F':' '{print $1}' | awk -F'_' '{print $1}' | grep -v ".bb" | grep -v ".inc" | uniq)"

echo "$PTEST_LIST"
