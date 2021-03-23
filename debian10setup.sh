sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a

sudo tee /etc/modules-load.d/kubernetes.conf<<EOF
br_netfilter
overlay
EOF

sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

VERSION=1.20
OS=Debian_10
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
sudo echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo echo "deb http://deb.debian.org/debian buster-backports main" | sudo tee /etc/apt/sources.list.d/backports.list
sudo curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /usr/share/keyrings/crio.gpg add -
sudo echo "deb [signed-by=/usr/share/keyrings/crio.gpg] https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
sudo echo "deb [signed-by=/usr/share/keyrings/crio.gpg] http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list

sudo apt update
sudo apt -y upgrade
sudo apt-get -y -t buster-backports install libseccomp2
sudo apt -y install vim nano git curl wget kubelet kubeadm kubectl cri-o cri-o-runc

sudo systemctl daemon-reload
sudo systemctl enable crio kubelet

sudo echo 'KUBELET_EXTRA_ARGS=--feature-gates="AllAlpha=false,RunAsGroup=true" --container-runtime=remote --container-runtime-endpoint='unix:///var/run/crio/crio.sock' --runtime-request-timeout=10m --cgroup-driver="systemd"' | sudo tee /etc/default/kubelet

sudo systemctl restart crio kubelet
sudo kubeadm config images pull
sudo systemctl reboot
