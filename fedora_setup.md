# Fedora 37 Setup Instructions

These instructions are based on the ones at [zews.org](https://www.zews.org/k8s-1-19-on-fedora-33-with-kubeadm-and-a-gpu/), combined with the [kubeadm installation instructions](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/), but with some changes for a flannel-based single-node setup.

1. Enable kubernetes repos:
```
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
```
Note that repo\_gpgcheck is set to 0. There is a bug with the GPG check and their repo. See: https://github.com/kubernetes/kubernetes/issues/110667
2. Set SELinux to permissive:
`
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
`   
3. Install cri-o: `sudo dnf install -y cri-o`
4. Modify /etc/cni/net.d/100-crio-bridge.conf and change the first "subnet" to "10.244.0.0/16"
5. Install kubeadm, kubelet, kubectl: `sudo dnf install -y --disableexcludes=kubernetes kubelet kubeadm kubectl`
6. Enable containerd and kubelet: `sudo systemctl enable --now containerd && sudo systemctl enable kubelet`
7. Enable required modules on boot: 

```
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system
```
8. Edit the GRUB_CMDLINE_LINUX line in /etc/default/grub and add: 
`systemd.unified_cgroup_hierarchy=0`

9. Update grub: 
`sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`

10. Disable swap:
`sudo touch /etc/systemd/zram-generator.conf`

11. Open required ports in firewalld (there may be others depending on network configuration):
```
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=6443/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=2379-2380/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=10250/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=10259/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=10257/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=30000-32767/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=8472/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=8472/udp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=8285/tcp
sudo firewall-cmd --zone=FedoraServer --permanent --add-port=8285/udp
sudo systemctl restart firewalld
```
12. Reboot the system

13. Initialize the cluster:
`sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --cri-socket=/var/run/containerd/containerd.sock`

14. Copy the kubeconfig:
```
sudo mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
15. Remove taint from the control-plane node (i.e. allow pods to start on control-plane):
`kubectl taint nodes --all node-role.kubernetes.io/control-plane-`

16. Add flannel (allows network pods to run properly):
`kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml`

17. Install iproute-tc (required for kubeadm init):
`sudo dnf install -y iproute-tc`

18. Copy (or link) /opt/cni/bin/flannel to /usr/libexec/cni/flannel (otherwise coredns pods will be stuck at ContainerCreating):
`sudo cp /opt/cni/bin/flannel /usr/libexec/cni/`

19. Install Tekton components:
```
kubectl apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml
kubectl apply --filename https://storage.googleapis.com/tekton-releases/dashboard/latest/release.yaml
```
20. Make the Tekton Dashboard accessible externally by running the following and changing spec.type from "ClusterIP" to "NodePort":
`kubectl edit svc tekton-dashboard -n tekton-pipelines`
