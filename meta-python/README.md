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
   4. eventlistener.yaml
   5. serviceaccount.yaml
   6. triggertemplate.yaml
   7. triggerbinding.yaml
   8. cronjob.yaml
3. `kubectl create -f` the following for **manual** runs:
   1. pipeline-run.yaml
   2. (Only to run the individual tasks) "-run.yaml" files. This is
      not required if running the whole pipeline as in step 3.i.

## What Are These Things?!

While the purpose/functionality of the setup and build YAML files may be
fairly apparent from their content (and from other Tekton examples you
may have read), where it gets tricky is the build triggering portion of
the overall pipeline. More specifically, the combination of the
following files serves the same purpose that you get from something like
Jenkins' build pipeline with the "Build Periodically" option filled out:

- eventlistener.yaml
- serviceaccount.yaml
- triggertemplate.yaml
- triggerbinding.yaml (not actually used right now)
- cronjob.yaml

An EventListener, according to the
[documentation](https://tekton.dev/docs/triggers/eventlisteners/),
processes incoming HTTP events with JSON payloads and uses them to
create Tekton resources via TriggerTemplates (and TriggerBindings, if
you want to extract data from these events to pass to the resources).
The cronjob for this pipeline uses `curl -X POST` to contact the
EventListener without actually sending any data, since none is currently
required to start the (mostly hard-coded) build pipeline. This will
likely change in the future!

## Limitations

- No QEMU in containers for meta-python-ptest-image (yet), and therefore
  the testimage-task.yaml steps have not been added to the meta-python
  pipeline
- The line getting the recipe list in build-task.yaml breaks on some
  punctuation in subject lines, e.g. "python3-<recipeA>/python3-<recipeB>"
  if multiple recipes are altered. It should be expanded to handle more
  advanced subject lines.
