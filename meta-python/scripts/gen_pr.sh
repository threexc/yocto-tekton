#!/bin/bash

git fetch upstream
git checkout master-next
git branch -D meta-python-merge
git push -u origin -d meta-python-merge
git reset --hard upstream/master-next
git push -u origin master-next --force
git checkout master
git reset --hard upstream/master
git push -u origin master --force
git checkout -b meta-python-merge
git log --oneline master-next master..master-next | grep -E 'python3-|meta-python' | awk '{print $1}' | tac | xargs git cherry-pick -s
git push -u origin meta-python-merge
