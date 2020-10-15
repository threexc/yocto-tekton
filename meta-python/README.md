## Usage Instructions

**Note:** The triggertemplate.yaml, log-task-run.yaml,
build-task-run.yaml, setup-workspace-task-run.yaml, and
pipeline-run.yaml files have hard-coded paths in them at the moment
which are specific to the author's system. You'll need to change them
(or create the same paths) for them to work!

1. (Optional) Prepare the [sstate deployment](../sstate/README.md)
2. `kubectl apply -f` the following:
   1. setup-workspace.yaml
   2. build-task.yaml
   3. log-task.yaml
   4. pipeline.yaml
   5. eventlistener.yaml
   6. serviceaccount.yaml
   7. triggertemplate.yaml
   8. triggerbinding.yaml
   9. cronjob.yaml
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
