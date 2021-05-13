#!/bin/bash

# Read line-by-line from $COMMIT_LOG, and get the recipe filenames. Make sure to handle the case where
# --diff-filter shows three words (e.g. when a version upgrade is made, it shows the diff-filter flag, 
# the old filename, and the new filename
while read -r line
do
  LINE_LENGTH=$(echo "$line" | wc -w)
  if [ "$LINE_LENGTH" = "3" ]; then
	  RECIPE_NAME=$(echo "$line" | awk '{print $3}' | awk -F/ '{print $NF}' | sed 's/_.*//' | sed 's/\..*//')
  elif [ "$LINE_LENGTH" = "2" ]; then
	  RECIPE_NAME=$(echo "$line" | awk '{print $2}' | awk -F/ '{print $NF}' | sed 's/_.*//' | sed 's/\..*//')
  else
	  echo "Something went wrong with getting recipe names."
      exit 1
  fi

  # Handle the case where a .inc file was modified, and the "recipe" it reports is e.g. python-grpcio-tools
  # instead of python3-grpcio-tools. Do this by splitting the recipe string on the first hyphen and adding
  # at the end of the prefix, before re-combining
  if [ $? -eq 1 ]; then
	  PREFIX=$(echo "$RECIPE_NAME" | cut -d'-' -f1)
	  SUFFIX=$(echo "$RECIPE_NAME" | cut -d'-' -f2)
	  RECIPE_NAME="${PREFIX}3-${SUFFIX}"
  fi


  # Make sure what we've parsed is actually a python recipe.
  # If (and only if) it is, then add it to RECIPE_LIST
  PYTHON_CHECK=$(echo "$RECIPE_NAME" | grep "python3")
  if [ "$?" -eq 0 ]; then
	  RECIPE_LIST+="${RECIPE_NAME} "
  fi

  echo $RECIPE_LIST
done < <(printf '%s\n' "$1")
