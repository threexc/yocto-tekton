#!/bin/bash

REPO_DIR="meta-openembedded"
LAYER="meta-python"

for i in "$@"
do
    case $i in
        --repo-dir=*)             REPO_DIR="${i#*=}" ;;
        --layer=*)                LAYER="${i#*=}" ;;
    esac
    shift
done

# Get the latest python recipe changes and bitbake them using --diff-filter for Added (A), Copied (C), 
# Modified (M), or Renamed (R) files. The filter character lines will always start with an upper-case 
# letter (commit hashes don't use them). Also ignore deleted files (D flag to --diff-filter)
COMMIT_LOG=$(git -C "$REPO_DIR" log --name-status --oneline origin/master..origin/master-next --find-renames --diff-filter=ACMR | grep "$LAYER" | grep "^[A-Z]")
RECIPE_NAME=""
RECIPE_LIST=""

# Exit cleanly if there is no difference between master and master-next
if [ ! -z "${COMMIT_LOG}" ]; then

    # Read line-by-line from $COMMIT_LOG, and get the recipe filenames. Make sure to handle the case where
    # --diff-filter shows three words (e.g. when a version upgrade is made, it shows the diff-filter flag, 
    # the old filename, and the new filename
    while read -r line
    do
        LINE_LENGTH=$(echo "$line" | wc -w)
        if [ "$LINE_LENGTH" = "3" ]; then
            RECIPE_NAME=$(echo "$line" | awk '{print $3}' | awk -F/ '{print $NF}' | sed 's/_.*//' | sed 's/\..*//')
        else
            RECIPE_NAME=$(echo "$line" | awk '{print $2}' | awk -F/ '{print $NF}' | sed 's/_.*//' | sed 's/\..*//')
        fi
        
        # For meta-python, handle the case where a .inc file was modified, and the "recipe" it reports is e.g. 
        # python-grpcio-tools instead of python3-grpcio-tools. Do this by splitting the recipe string on the 
        # first hyphen and adding at the end of the prefix, before re-combining
        if [ "$LAYER" == "meta-python" ] && [ "$?" -eq "1" ]; then
            PREFIX=$(echo "$RECIPE_NAME" | cut -d'-' -f1)
            SUFFIX=$(echo "$RECIPE_NAME" | cut -d'-' -f2)
            RECIPE_NAME="${PREFIX}3-${SUFFIX}"
        fi

        # Make sure what we've parsed is actually a python recipe.
        # If (and only if) it is, then add it to RECIPE_LIST
        if [ "$LAYER" == "meta-python" ]; then
            PYTHON_CHECK=$(echo "$RECIPE_NAME" | grep python3)
            if [ $? -eq 0 ]; then
                RECIPE_LIST+="${RECIPE_NAME} "
            fi
        else
            RECIPE_LIST+="${RECIPE_NAME} "
        fi

    done < <(printf '%s\n' "$COMMIT_LOG")
else
    RECIPE_LIST=""
fi

echo "${RECIPE_LIST}"
