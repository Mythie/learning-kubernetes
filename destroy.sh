#!/usr/bin/env bash

aws help > /dev/null

if [[ $? != 0 ]]; then
  echo "[FATAL] AWS CLI must be installed to create the cluster"
  exit 1
fi

echo "[INFO] Destroying preconfigured deployments from ./deployments folder"
for file in $(ls -r ./deployments/*.yaml); do
  echo "[INFO] Destroying $file"
  kubectl delete -f $file
done;

echo "[INFO] Destroying Infrastructure"
terraform destroy -auto-approve