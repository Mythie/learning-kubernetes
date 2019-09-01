locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.eks_worker_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.kube.endpoint}
    certificate-authority-data: ${aws_eks_cluster.kube.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
KUBECONFIG

  cluster-autoscaler = templatefile("./cluster-autoscaler.template", { cluster-name = "${var.cluster-name}", region = "${var.region}" })
}

output "config-map" {
  value = "${local.config_map_aws_auth}"
}


output "kubeconfig" {
  value = "${local.kubeconfig}"
}

output "cluster-name" {
  value = "${var.cluster-name}"
}

output "cluster-autoscaler" {
  value = "${local.cluster-autoscaler}"
}
