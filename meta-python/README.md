## Basic Structure

1. setup-workspace clones poky and meta-openembedded if they aren't
   already present, then pulls the latest patches for master and
   master-next respectively;
2. build-task grabs the module names from the subject lines of the
   master-next commit messages and passes them to bitbake.

## Usage Instructions

1. (Optional) Prepare the sstate deployment;
2. `kubectl apply -f` the following:
   1. setup-workspace.yaml
   2. build-task.yaml
   3. pipeline.yaml
3. `kubectl create -f` the following:
   1. pipeline-run.yaml
   2. (Only to run the individual tasks) "-run.yaml" files. This is
      not required if running the whole pipeline.

## Limitations

- No QEMU in containers for meta-python-ptest-image (yet)
- The line getting the recipe list in build-task.yaml breaks on some
  punctuation in subject lines, e.g. "python3-<recipeA>/python3-<recipeB>"
  if multiple recipes are altered. It should be expanded to handle more
  advanced subject lines.
