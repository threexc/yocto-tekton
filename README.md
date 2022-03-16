# yocto-tekton

Table of Contents
=================

* [yocto-tekton](#yocto-tekton)
   * [Overview](#overview)
   * [Dockerfiles](#dockerfiles)
   * [Instructions for Setting Up Kubernetes and Tekton with CRI-O on Fedora](#instructions-for-setting-up-kubernetes-and-tekton-with-cri-o-on-fedora)
   * [The meta-python Pipeline](#the-meta-python-pipeline)
      * [Overview and Usage](#overview-and-usage)
      * [The nettools Pod](#the-nettools-pod)
      * [Notes/Lessons Learned](#noteslessons-learned)
   * [Frequently Asked Questions](#frequently-asked-questions)
   * [To-Do](#to-do)
   * [Credits](#credits)

## Overview

This is a repository of configuration files meant for maintaining the
layers of the [Yocto Project](https://www.yoctoproject.org/). It
originated as a simple set of Tekton pipeline resources for Kubernetes
that were (and are still) used to help maintain the [meta-python
layer](https://layers.openembedded.org/layerindex/branch/master/layer/meta-python/),
but it continues to evolve to support other layers and related
processes, in addition to serving as a set of examples for building
pipelines with Docker, k8s, and Tekton.

See the instructions for configuring a k8s cluster in the coming sections 
to get started.

## Dockerfiles

The [Dockerfiles](Dockerfiles) are used to handle the majority of the 
deployments and pipelines created through the rest of the repository's 
content.

1. Dockerfile-buildspace is the catch-all container for actual builds,
   which includes all of the tools necessary to successfully run bitbake
   for various recipes;
2. Dockerfile-nettools is a container that is best used as a debug pod
   when testing new deployments, pods, etc. and their configurations
   (e.g. if you want to make sure that an httpd deployment is exposed
   where you think it is)

## Setup Instructions

See [fedora_setup.md](fedora_setup.md)

## The meta-python Pipeline

### Overview and Usage

The meta-python pipelines are examples of how one might build a CI/CD pipeline
that performs common Yocto layer maintainer tasks. There are two
different pipelines:

1. patch-pipeline
2. container-pipeline

Both of these share a common task, "update-workspace", which clones the poky, 
meta-openembedded, and yocto-tekton repositories into the hostPath specified in
the pipelines (or updates these repositories to the latest master, master-next, 
and main commits, respectively, if the repos are already present). Each
pipeline also comes with a distinct EventListener and CronJob that will
automatically trigger them once per day.

patch-pipeline does the following:
1. Identify any patches applied to the master-next branch of the
   meta-openembedded layer that are for meta-python recipes and adds the recipe
   names to a build list;
2. Triggers a build of all of those recipes with bitbake;
3. Outputs a short list of all of the identified and built recipes after
   completion (if the builds succeeded)

container-pipeline:
1. Builds the meta-python-ptest-image target as a container filesystem;
2. Uses Kaniko to build a container image from the completed ptest image and
   pushes it to a local registry;
3. Pulls the image from that registry to run as the container for a test task,
   and executes the "ptest-runner" command

Both of these pipelines make basic use of Kubernetes' built-in Kustomize
functionality to simplify templating the individual pipelines, share
resource templates (such as the aforementioned update-workspace task),
and instantiate supporting services (such as the yt-registry deployment
that container-pipeline uses to store its test images). For the
end-user, this ultimately means that adding these pipelines to the
single-node cluster can be as simple as running this command inside the
container-pipeline and/or patch-pipeline directories:

`kubectl apply -k .`

**Note:** The TriggerTemplate spec in each pipeline has a hostPath value of
/tekton/pipelines/meta-python, which is specific to the author's system. If 
you want the pipeline build artifacts to be created in a different location, 
you will need to edit this field, or create the /tekton/pipelines/meta-python 
path on the cluster node and ensure it that the correct permissions are set.

### The nettools Pod

While both meta-python pipelines feature automatic runs thanks to their
CronJob/EventListener combinations, it is possible to trigger them
manually as required. To help in doing so, the author also created a
"nettools" pod for the single-node cluster that can be used to (among
other things) trigger the builds.

The nettools pod is created by running:

`kubectl run -i --tty --attach nettools --image=threexc/nettools`

If it is instantiated but you are not currently attached, you can attach
to it by running:

`kubectl exec -it nettools -- /bin/bash`

And then running the following (check the EventListener naming
conventions for exact syntax):

`curl -X POST http://el-meta-python-listener.tekton-pipelines.svc.cluster.local:8080`

Finally, `tkn pipelinerun logs --last -f -n tekton-pipelines` or the
Tekton Dashboard allow viewing of the in-progress or complete pipelines.

### Notes/Lessons Learned

- Helm doesn't like "generateName" fields (making adding the Tekton
  parts to the chart difficult):
  https://github.com/helm/helm/issues/3348

## To-Do

- Better patch queue/identification for meta-python and poky pipelines
- Start using stuff from the [Tekton
  Catalog](https://github.com/tektoncd/catalog)
- Get QEMU working in the testimage container
  - Do it with KVM and tap/tun

## Credits

TOC generated with the help of
[gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

GIFs generated with [peek](https://github.com/phw/peek)
