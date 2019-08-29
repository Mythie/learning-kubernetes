provider "aws" {
  region = "${var.region}"
}

resource "aws_eks_cluster" "kube" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eks_cluster_role.arn}"

  vpc_config {
    subnet_ids         = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]
    security_group_ids = ["${aws_security_group.kube.id}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.cluster-cluster-policy",
    "aws_iam_role_policy_attachment.cluster-service-policy"
  ]
}