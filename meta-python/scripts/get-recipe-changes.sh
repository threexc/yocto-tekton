#!/bin/bash

LAYERDIR="meta-openembedded"
SUBGROUP="python"

COMMIT_LOG="$(cd "$LAYERDIR" && git log --name-status --oneline --grep="$SUBGROUP" origin/master..origin/master-next --find-renames --diff-filter=ACMR | grep "^[A-Z]" | grep "$SUBGROUP")"

echo "$COMMIT_LOG"
