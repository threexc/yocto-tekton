# yocto-tekton

This is a repository of configuration files meant for maintaining the
layers of the [Yocto Project](https://www.yoctoproject.org/). It
originated as a simple set of Tekton pipeline resources for Kubernetes
that were (and are still) used to help maintain the [meta-python
layer](https://layers.openembedded.org/layerindex/branch/master/layer/meta-python/),
but it continues to evolve to support other layers and related
processes, in addition to serving as a set of examples for building
pipelines with Docker, k8s, and Tekton.

See the instructions for configuring a k8s
cluster below to get started, or view each directory's
README.md to learn more about what they do.

Maintainer: Trevor Gamblin <trevor.gamblin@windriver.com>

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
10. Install Tekton Triggers: `kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml`
11. Install Tekton Dashboard: `kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/tekton-dashboard-release.yaml`
12. Install [Helm](https://helm.sh/docs/intro/install/)
13. (Recommended) Get the [Tekton CLI](https://tekton.dev/docs/cli/)
14. (Recommended) Install k9s: `go get -u github.com/derailed/k9s`

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

### Using the meta-python Pipeline

### To-Do

- Use configmaps and triggerbindings to remove hard-coding from all
  pipelines
- Better patch queue/identification for meta-python and poky pipelines
- Start using stuff from the [Tekton
  Catalog](https://github.com/tektoncd/catalog)
- Get QEMU working in the testimage container
  - Do it with KVM and tap/tun
- Figure out Tanka/Helm for entire sstate deployment + pipelines

### Frequently Asked Questions

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
