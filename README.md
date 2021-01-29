# yocto-tekton

Table of Contents
=================

   * [yocto-tekton](#yocto-tekton)
   * [Table of Contents](#table-of-contents)
      * [Overview](#overview)
      * [Dockerfiles](#dockerfiles)
      * [Instructions for Setting Up Kubernetes and Tekton with CRI-O on Fedora 33](#instructions-for-setting-up-kubernetes-and-tekton-with-cri-o-on-fedora-33)
      * [Using the meta-python Pipeline](#using-the-meta-python-pipeline)
         * [Instructions](#instructions)
         * [The Pipeline in Action - Tekton CLI](#the-pipeline-in-action---tekton-cli)
         * [The Pipeline in Action - Tekton Dashboard](#the-pipeline-in-action---tekton-dashboard)
      * [The Shared State Deployment](#the-shared-state-deployment)
         * [Automatic Shared State](#automatic-shared-state)
         * [Instructions](#instructions-1)
         * [Helm Chart](#helm-chart)
         * [Notes/Lessons Learned](#noteslessons-learned)
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

## Instructions for Setting Up Kubernetes and Tekton with CRI-O on Fedora 33

The following steps are meant specifically for Fedora machines, but you
should be able to build a cluster on other distros using a similar
process. While cri-o is the runtime used for the Kubernetes cluster
example given here, you should also still be able to use Docker or other
tools such as Podman on the same system for manually building and
running containers.

The instructions at
[zews.org](https://www.zews.org/k8s-1-19-on-fedora-33-with-kubeadm-and-a-gpu/)
are fantastic, but there are some differences for the simple,
single-node setup catered towards Yocto builds. For completeness (and in
case that information disappears), I have reproduced most of that
content below. Note that the instructions here diverge from theirs at
step 17, when we install Flannel (instead of Calico).

1. Enable Kubernetes repos: 
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```
2. Disable SELinux: `sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/'
   /etc/selinux/config`
3. Enable cri-o nightly repo: 
```
dnf -y module enable cri-o:nightly
dnf install -y cri-o
```
4. Install kubeadm, kubelet, kubectl: `dnf  install -y
   --disableexcludes=kubernetes kubelet kubeadm kubectl
`
5. Enable cri-o and kubelet on boot: `systemctl enable cri-o && sudo
   systemctl enable kubelet
`
6. Set the cgroup driver: `echo
   "KUBELET_EXTRA_ARGS=--cgroup-driver=systemd" | sudo tee
/etc/sysconfig/kubelet`
7. Enable required modules on boot: 
```
tee /etc/modules-load.d/crio-net.conf <<EOF
overlay
br_netfilter
EOF
```
8. Set sysctl options: 
```
tee /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```
9. Edit the `GRUB_CMDLINE_LINUX` line in /etc/default/grub and add:
    `systemd.unified_cgroup_hierarchy=0
`
10. Update grub: `grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
11. Disable swap: `touch /etc/systemd/zram-generator.conf`
12. Disable firewall (will figure out another workaround in the future):
`systemctl disable firewalld.service`
13. Reboot the system
14. Initialize the cluster: `kubeadm init
    --pod-network-cidr=10.244.0.0/16
--cri-socket=/var/run/crio/crio.sock`
15. `mkdir -p $HOME/.kube`
    `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`
    `sudo chown $(id -u):$(id -g) $HOME/.kube/config`
16. Remove the taint from the master node (i.e. allow pods to start on
    the control node): `kubectl taint nodes --all
node-role.kubernetes.io/master-`
17. Setup flannel: `kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`
18. Install [CNI plugins](https://medium.com/@liuyutong2921/network-failed-to-find-plugin-bridge-in-path-opt-cni-bin-70e7156ceb0b)
so that the network pods run
19. Install Tekton Pipelines: `kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml`
20. Install Tekton Triggers: `kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml`
21. Install Tekton Dashboard: `kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml`
22. (Recommended) Get the [Tekton CLI](https://tekton.dev/docs/cli/)
23. (Recommended) Install [k9s](https://github.com/derailed/k9s)
24. To make the Tekton Dashboard accessible from remote machines, run
    `kubectl edit svc tekton-dashboard -n tekton-pipelines`, find the
`spec.type` field, and change it from `clusterIP` to `NodePort`, then
save and exit. Running `kubectl get svc -A` will then show you a list of
services running in the cluster, including the tekton-dashboard, which
will have a port number assigned to it. This can be accessed from your
browser by visiting `<NodeIP>:<NodePort>`.
25. Edit /etc/crio/crio.conf and change the `pids_limit` field to use a
    higher value. Keeping it at 1024 will almost certainly cause builds
even for single recipes to fail. I have found success with the
meta-python pipeline with `pids_limit=4096`, but chances are this needs
to be much higher for larger builds.

## Using the meta-python Pipeline

### Instructions

1. Edit the "volumes.yaml" file and set the hostPath.path value with
   your preferred location for builds (make sure permissions are set,
   and change the volume sizes if necessary)

2. `kubectl apply -f` the following:
    1. volumes.yaml
    2. tasks.yaml
    3. pipeline.yaml
    4. serviceaccount.yaml
    5. triggers.yaml
    6. (Optional) Do a test run with `kubectl create -f pipeline-run.yaml`

The meta-python pipeline will now trigger twice per day and build in the
specified directory.

**Note 1:** The triggertemplate.yaml, log-task-run.yaml,
build-task-run.yaml, setup-workspace-task-run.yaml, and
pipeline-run.yaml files have hard-coded paths in them at the moment
which are specific to the author's system. You'll need to change them
(or create the same paths) for them to work!

**Note 2:** These instructions assume that you've already done the setup for
the [sstate deployment](#sstate)

**Note 3:** There are "run" versions of the tasks in the taskruns/
directory, but they are not required to created with `kubectl create -f <filename>` 
unless you want to run a manual build; the cronjob and eventlistener files will
setup an automatic build process.

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

![meta-python pipeline](https://github.com/threexc/yocto-tekton/blob/main/media/extended_demo.gif)

### The Pipeline in Action - Tekton Dashboard

This view is the same idea as the CLI example above, except we're
browsing the running meta-python pipeline via the Tekton Dashboard.

![meta-python pipeline](https://github.com/threexc/yocto-tekton/blob/main/media/meta-python-dashboard.gif)

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
