## Instructions

1. `kubectl apply -f` the following:
   1. setup-workspace.yaml
   2. build-task.yaml
   3. pipeline.yaml
2. `kubectl create -f` the following:
   1. pipelinerun.yaml
   2. (Only to run the individual tasks) "-run.yaml" files
