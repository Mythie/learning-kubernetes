#!/usr/bin/env bash

aws help > /dev/null

if [[ $? != 0]]; then
  echo "[FATAL] AWS CLI must be installed to create the cluster"
  exit 1
fi

terraform apply

terraform output config-map > config-map.yaml

aws eks update-kubeconfig --name kube

kubectl apply -f config-map.yaml

echo "[SUCCESS] You're ready to start using Kubernetes"

kubectl get svc && kubectl get nodes
