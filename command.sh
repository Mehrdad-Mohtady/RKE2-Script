mkdir -p /root/rke2-artifacts
mv /var/lib/rancher/rke2/agent/images/{rke2.linux-amd64.tar.gz,rke2-images*.tar.*,sha256sum-amd64.txt} /root/rke2-artifacts/
INSTALL_RKE2_ARTIFACT_PATH=/root/rke2-artifacts sh /var/lib/rancher/rke2/agent/images/install.sh --cni=cilium


mkdir ~/.kube
cp /var/lib/rancher/rke2/bin/kubectl /usr/bin/kubectl
cp /etc/rancher/rke2/rke2.yaml ~/.kube/config

kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml get nodes


# add once (root or your user)
echo "alias ctrk='sudo /var/lib/rancher/rke2/bin/ctr -a /run/k3s/containerd/containerd.sock -n k8s.io'" >> ~/.bashrc
. ~/.bashrc

# now use:
ctrk c ls        # containers
ctrk i ls        # images
ctrk t ls        # tasks (running containers)



sudo tee /etc/rancher/rke2/config.yaml >/dev/null <<'YAML'
token: supersecret
cni: cilium
tls-san:
  - 192.168.94.32
YAML


sudo systemctl status rke2-server

sudo systemctl stop rke2-server

sudo systemctl start rke2-server

sudo systemctl enable --now rke2-server

ls -1 /var/lib/rancher/rke2/bin/*
/var/lib/rancher/rke2/bin/containerd
/var/lib/rancher/rke2/bin/containerd-shim
/var/lib/rancher/rke2/bin/containerd-shim-runc-v1
/var/lib/rancher/rke2/bin/containerd-shim-runc-v2
/var/lib/rancher/rke2/bin/crictl
/var/lib/rancher/rke2/bin/ctr
/var/lib/rancher/rke2/bin/kubectl
/var/lib/rancher/rke2/bin/kubelet
/var/lib/rancher/rke2/bin/runc



# Current runtime config
kubectl -n kube-system exec ds/cilium -c cilium-agent -- cilium config

# Endpoints/enforcement per pod
kubectl -n kube-system exec ds/cilium -c cilium-agent -- cilium endpoint list

# Services Cilium knows about (LB maps)
kubectl -n kube-system exec ds/cilium -c cilium-agent -- cilium service list

# Quick cluster health ping mesh
kubectl -n kube-system exec ds/cilium -c cilium-agent -- cilium-health status --probe
