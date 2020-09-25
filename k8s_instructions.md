## Instructions for Setting Up Kubernetes and Tekton With kubeadm

### Prerequisites

- A fully-configured Go development environment
- Ability to use `sudo`
- Docker, or a similar containerization tool (may need additional
  configuration)

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
12. (Recommended) Get the Tekton CLI: `https://tekton.dev/docs/cli/`
13. For quickly making deployed services accessible remotely, do
    `kubectl edit svc <servicename> -n <namespace>` (e.g. `kubectl edit
svc tekton-dashboard -n tekton-pipelines`), search for a line that says
`type: ClusterIP` and change it to say `type: NodePort`, then save and
check the status of the service. It should now have a port in the 30000+
range that you can access using `<IP>:<PORT>` in your browser from
machines on the same network as the node.

