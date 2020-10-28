# yocto-tekton

Table of Contents
=================

   * [yocto-tekton](#yocto-tekton)
   * [Table of Contents](#table-of-contents)
      * [Overview](#overview)
      * [Dockerfiles](#dockerfiles)
      * [Instructions for Setting Up Kubernetes and Tekton With
        kubeadm](#instructions-for-setting-up-kubernetes-and-tekton-with-kubeadm)
         * [Prerequisites](#prerequisites)
         * [Instructions](#instructions)
         * [Setting up Docker on Fedora
           32](#setting-up-docker-on-fedora-32)
      * [The Shared State Deployment](#the-shared-state-deployment)
         * [Automatic Shared State](#automatic-shared-state)
         * [Instructions](#instructions-1)
         * [Helm Chart](#helm-chart)
         * [Notes/Lessons Learned](#noteslessons-learned)
      * [Using the meta-python
        Pipeline](#using-the-meta-python-pipeline)
         * [The Pipeline in Action - Tekton
           CLI](#the-pipeline-in-action---tekton-cli)
         * [The Pipeline in Action - Tekton
           Dashboard](#the-pipeline-in-action---tekton-dashboard)
         * [Instructions](#instructions-2)
         * [What Are These Things?!](#what-are-these-things)
         * [Limitations](#limitations)
      * [Using the poky Pipeline](#using-the-poky-pipeline)
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

## Instructions for Setting Up Kubernetes and Tekton With kubeadm

### Prerequisites

- A fully-configured Go development environment [see the installation
  guide](https://golang.org/doc/install)
- Ability to use `sudo`
- Docker, or a similar containerization tool (may need additional
  configuration). See "Setting Up Docker on Fedora 32"

### Instructions

1. Turn off swap: `sudo swapoff -a`
2. Follow the instructions to install kubeadm, kubectl, and kubelet from
   the Kubernetes [documentation](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
3. Initialize k8s and set the pod CIDR for flannel: `sudo kubeadm init --pod-network-cidr=10.244.0.0/16`
4. Save the join string from the output somewhere accessible
   (e.g. $HOME/.kube/join.txt)
5. Copy admin.conf to your .kube directory: `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`
6. Set ownership of admin.conf: `sudo chown $(id -u):$(id -g) $HOME/.kube/config`
7. Setup flannel: `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`
8. Install [CNI plugins](https://medium.com/@liuyutong2921/network-failed-to-find-plugin-bridge-in-path-opt-cni-bin-70e7156ceb0b)
so that the network pods run
8. (If the master node will also run builds) Taint the node: ```kubectl taint nodes --all node-role.kubernetes.io/master-```
9. Install Tekton Pipelines: `kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml`
10. Install Tekton Triggers: `kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml`
11. Install Tekton Dashboard: `kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml`
12. Install [Helm](https://helm.sh/docs/intro/install/)
13. (Recommended) Get the [Tekton CLI](https://tekton.dev/docs/cli/)
14. (Recommended) Install [k9s](https://github.com/derailed/k9s)
15. To make the Tekton Dashboard accessible from remote machines, run
    `kubectl edit svc tekton-dashboard -n tekton-pipelines`, find the
`spec.type` field, and change it from `clusterIP` to `NodePort`, then
save and exit. Running `kubectl get svc -A` will then show you a list of
services running in the cluster, including the tekton-dashboard, which
will have a port number assigned to it. This can be accessed from your
browser by visiting `<NodeIP>:<NodePort>`.

### Setting up Docker on Fedora 32

The following instructions only apply if you want to closely match the
OS configuration used for the original cluster, i.e. you want to use k8s
with **Docker** on Fedora 32. For other systems, you should follow
equivalent instructions (if you can't install from the package manager).
Other container runtimes are currently untested, but information about
configuration needed e.g. for podman would be greatly appreciated!

1. `sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=0"`
2. Reboot the system
3. Follow the instructions at [Computing for Geeks](https://computingforgeeks.com/how-to-install-docker-on-fedora) 
for setting up Docker Community Edition on Fedora 32.

## The Shared State Deployment

### Automatic Shared State

The contents of the [sstate/automated](sstate/automated) directory will configure a 
cronjob and eventlistener to rebuild the core-image-\* group of images in a
directory once per day (similar to the contents of `meta-python`), which can 
then be used in the `SSTATE_MIRROR` variable in builds. The deployment.yaml,
service.yaml, pv.yaml, and pvc.yaml are used to provision that build space 
and also to serve it as a browsable web interface in an httpd container.

### Instructions

`kubectl apply -f` the following:
1. pv.yaml
2. pvc.yaml
3. deployment.yaml
4. service.yaml
5. sstate-build-task.yaml
6. sstate-build-pipeline.yaml
7. eventlistener.yaml
8. serviceaccount.yaml
9. triggertemplate.yaml
10. triggerbinding.yaml
11. cronjob.yaml

**Note 1:** You may see warnings about the usage of `kubectl apply` vs
`kubectl create`. These are OK - the proper way to use some resources
(deployments, *Run types, etc.) is with the latter command, but they
should still work with the former.

**Note 2:** There are "run" versions of the pipelines and tasks, but they
are not required to created with `kubectl create -f <filename>` unless
you want to run a manual build; the cronjob and eventlistener files will
setup an automatic build process.

**Note 3:** You will need to modify the hard-coded paths in
triggertemplate.yaml (and pipelinerun.yaml/taskrun.yaml) for things to
work (or create the same paths on your build node(s)).

### Helm Chart

An example of a Helm chart that can be used to deploy the httpd server
portion is in the `helm-chart` directory. It can be installed with the
following command:

`helm install <deployment_name> --namespace tekton-pipelines
helm-chart/`

Where <deployment_name> can be whatever you'd like (meta-python expects
it to be "yocto-sstate" by default).

**Note:** This process is mainly for demonstrative purposes right now -
Helm appears to be too limited for supporting the Tekton CRDs like
pipelines at the moment (see below).

### Notes/Lessons Learned

- Helm doesn't like "generateName" fields (making adding the Tekton
  parts to the chart difficult):
  https://github.com/helm/helm/issues/3348

## Using the meta-python Pipeline

### The Pipeline in Action - Tekton CLI

The following GIF shows the meta-python EventListener being triggered
from a pod created using the Dockerfile-nettools container. The nettools
container is mainly meant to help test k8s network configuration, but
since it can reach the EL, we can use it to manually trigger a new 
meta-python pipeline run by sending an empty POST (instead of waiting
for the meta-python cronjob to do it):

`curl -X POST http://el-meta-python-listener.tekton-pipelines.svc.cluster.local:8080`

The nettools pod is created by running:

`kubectl run -i --tty --attach nettools --image=threexc/nettools`

If it is instantiated but you are not currently attached, you can attach
to it by running:

`kubectl exec -it nettools -- /bin/bash`

Finally, `tkn pipelinerun logs --last -f -n tekton-pipelines` allows us
to follow the logs of the last pipelinerun in the tekton-pipelines
namespace.

![meta-python pipeline](https://github.com/threexc/yocto-tekton/blob/main/media/meta-python-1.gif)

### The Pipeline in Action - Tekton Dashboard

This view is the same idea as the CLI example above, except we're
browsing the running meta-python pipeline via the Tekton Dashboard.

![meta-python pipeline](https://github.com/threexc/yocto-tekton/blob/main/media/meta-python-dashboard.gif)

### Instructions

**Note 1:** The triggertemplate.yaml, log-task-run.yaml,
build-task-run.yaml, setup-workspace-task-run.yaml, and
pipeline-run.yaml files have hard-coded paths in them at the moment
which are specific to the author's system. You'll need to change them
(or create the same paths) for them to work!

**Note 2:** These instructions assume that you've already done the setup for
the [sstate deployment](#sstate)

1. `kubectl apply -f` the following:
   1. setup-workspace.yaml
   2. build-task.yaml
   3. log-task.yaml
   4. pipeline.yaml
   5. eventlistener.yaml
   6. serviceaccount.yaml
   7. triggertemplate.yaml
   8. triggerbinding.yaml
   9. cronjob.yaml
2. `kubectl create -f` the following for **manual** runs:
   1. pipeline-run.yaml
   2. (Only to run the individual tasks) "-run.yaml" files. This is
      not required if running the whole pipeline as in step 3.i.

### What Are These Things?!

While the purpose/functionality of the setup and build YAML files may be
fairly apparent from their content (and from other Tekton examples you
may have read), where it gets tricky is the build triggering portion of
ghe overall pipeline. More specifically, the combination of the
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

### Limitations

- No QEMU in containers for meta-python-ptest-image (yet), and therefore
  the testimage-task.yaml steps have not been added to the meta-python
  pipeline

## Using the poky Pipeline

This is a limited functionality poky pipeline - it will grab the names
of recipes changed between origin/master and origin/master-next, and
build those as long as the recipe filename (once the version number has
been stripped) matches the actual recipe name.

## Frequently Asked Questions

1. **Why Use kubeadm and not Minikube (or another tool)?**

Minikube is great for getting one's feet wet with Kubernetes and Tekton,
but the extra work required to expand it to a more versatile cluster
using more of the production-ready resources available to the community
made it unviable for this project. kubeadm was the first of the
alternatives that the developers had success with, and the documentation
is reasonably plentiful. That being said, if you would like to try out
the resources found here on another platform, we would appreciate any
information about additional setup requirements and quirks.

2. **Why Turn Off Swap For Kubernetes?**

This is a complicated topic, but basically it seems that if swap were to
be enabled, it'd be much harder to guarantee consistent performance for
k8s pods. In lieu of swap, pods should have their resource requirements
met ahead of time. It is possible to run with swap by using the
`--fail-swap-on=false` flag when first configuring the cluster, but sane
and stable results are not guaranteed. See [this
link](https://github.com/kubernetes/kubernetes/issues/53533) for more
info.

3. **How Can I Contribute?**

The yocto-tekton project is still in the early stages and much is still
being decided, but if you're interested in helping out, you could do one
or more of the following (as examples):

   - Test out the setup and usage instructions and report any
     inconsistencies or problems you encounter
   - Experiment with other k8s services, container runtimes, etc.
   - Assist in making the tasks run as part of the meta-python and poky
     pipelines more robust

Submitting pull requests, and/or discussing via opening issues are the
best avenues right now. You can also reach Trevor via the `tgamblin`
username on Freenode IRC, or at `trevor.gamblin@windriver.com`.

## To-Do

- Use configmaps and triggerbindings to remove hard-coding from all
  pipelines
- Better patch queue/identification for meta-python and poky pipelines
- Start using stuff from the [Tekton
  Catalog](https://github.com/tektoncd/catalog)
- Get QEMU working in the testimage container
  - Do it with KVM and tap/tun
- Figure out Tanka/Helm for entire sstate deployment + pipelines

## Credits

TOC generated with the help of
[gh-md-toc](https://github.com/ekalinin/github-markdown-toc)

GIFs generated with [peek](https://github.com/phw/peek)
