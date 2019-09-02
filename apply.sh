#!/usr/bin/env bash

aws help > /dev/null

if [[ $? != 0 ]]; then
  echo "[FATAL] AWS CLI must be installed to create the cluster"
  exit 1
fi

terraform apply -auto-approve

mkdir outputs

terraform output config-map > ./outputs/config-map.yaml
terraform output cluster-autoscaler > ./outputs/cluster-autoscaler.yaml

echo "[SUCCESS] You're ready to start using Kubernetes"
aws eks update-kubeconfig --name $(terraform output cluster-name)

echo "[INFO] Applying Worker Node config"
kubectl apply -f ./outputs/config-map.yaml
echo "[INFO] Applying Cluster Autoscaler"
kubectl apply -f ./outputs/cluster-autoscaler.yaml

echo "[INFO] Waiting for workers to join cluster"
sleep 15

kubectl get svc && kubectl get nodes

echo "[INFO] Deploying preconfigured deployments from ./deployments folder"
for file in $(ls ./deployments/*.yaml); do
  echo "[INFO] Applying $file"
  kubectl apply -f $file
done;