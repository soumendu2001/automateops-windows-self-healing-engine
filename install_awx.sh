#!/bin/bash

set -e

echo "=================================="
echo "Updating OS"
echo "=================================="

sudo apt update -y
sudo apt upgrade -y

echo "=================================="
echo "Installing prerequisites"
echo "=================================="

sudo apt install -y \
    git \
    curl \
    wget \
    tar \
    make \
    gcc \
    python3-pip \
    ansible

echo "=================================="
echo "Installing K3s"
echo "=================================="

wget https://github.com/k3s-io/k3s/releases/latest/download/k3s

chmod +x k3s

sudo mv k3s /usr/local/bin/

sudo tee /etc/systemd/system/k3s.service > /dev/null <<EOF
[Unit]
Description=Lightweight Kubernetes
After=network.target

[Service]
Type=exec
ExecStart=/usr/local/bin/k3s server
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable k3s
sudo systemctl start k3s

echo "Waiting for K3s startup..."
sleep 60

echo "=================================="
echo "Configuring kubectl"
echo "=================================="

sudo ln -sf /usr/local/bin/k3s /usr/local/bin/kubectl

sudo mkdir -p ~/.kube

sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config

sudo chown $USER:$USER ~/.kube/config

PRIVATE_IP=$(hostname -I | awk '{print $1}')

sed -i "s/127.0.0.1/$PRIVATE_IP/g" ~/.kube/config

export KUBECONFIG=$HOME/.kube/config

sudo kubectl get nodes

echo "=================================="
echo "Installing Helm"
echo "=================================="

sudo  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

sudo helm version

echo "=================================="
echo "Deploying AWX Operator"
echo "=================================="

cd ~

sudo rm -rf awx-operator

sudo git clone https://github.com/ansible/awx-operator.git

cd awx-operator

sudo git checkout 2.19.1

sudo kubectl create namespace awx || true

export NAMESPACE=awx

make deploy

echo "Waiting for Operator Pod..."
sleep 30

echo "=================================="
echo "Patch kube-rbac-proxy image"
echo "=================================="

sudo kubectl set image deployment/awx-operator-controller-manager \
-n awx \
kube-rbac-proxy=quay.io/brancz/kube-rbac-proxy:v0.15.0

sudo kubectl rollout status deployment/awx-operator-controller-manager -n awx

echo "=================================="
echo "Creating AWX Instance"
echo "=================================="

cat > ~/awx.yaml <<EOF
apiVersion: awx.ansible.com/v1beta1
kind: AWX
metadata:
  name: awx
  namespace: awx
spec:
  service_type: nodeport
EOF

sudo kubectl apply -f ~/awx.yaml

echo "=================================="
echo "Waiting for AWX deployment"
echo "=================================="

echo "====================="
echo "Lets wait for 5 mins"
echo "====================="
sleep 300

sudo kubectl get pods -n awx

echo "=================================="
echo "Getting AWX Password"
echo "=================================="

sudo kubectl get secret awx-admin-password \
-n awx \
-o jsonpath="{.data.password}" | base64 -d

echo
echo "=================================="

echo "AWX service details"

sudo kubectl get svc -n awx

PUBLIC_IP=$(curl -s ifconfig.me)

echo
echo "Open AWX using:"
echo
echo "http://$PUBLIC_IP"
echo
echo "Check NodePort from:"
echo "kubectl get svc -n awx"

echo "=================================="
echo "Installation Complete"
echo "=================================="
