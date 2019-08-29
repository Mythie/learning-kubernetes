resource "aws_iam_instance_profile" "worker_profile" {
  name = "aws_worker_profile"
  role = "${aws_iam_role.eks_worker_role.name}"
}

locals {
  worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.kube.endpoint}' --b64-cluster-ca '${aws_eks_cluster.kube.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_configuration" "worker_launch_config" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.worker_profile.name}"
  image_id                    = "${var.ami-id}"
  instance_type               = "t3.medium"
  name_prefix                 = "kube-worker"
  security_groups             = ["${aws_security_group.kube.id}"]
  user_data_base64            = "${base64encode(local.worker-userdata)}"
  key_name                    = "${var.key-name}"

  root_block_device {
    volume_size = 20
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_configuration" "spot_worker_launch_config" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.worker_profile.name}"
  image_id                    = "${var.ami-id}"
  instance_type               = "t3.medium"
  name_prefix                 = "kube-spot-worker"
  security_groups             = ["${aws_security_group.kube.id}"]
  user_data_base64            = "${base64encode(local.worker-userdata)}"
  key_name                    = "${var.key-name}"
  spot_price                  = "${var.spot-price}"

  root_block_device {
    volume_size = 20
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "worker_autoscaling_group" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.worker_launch_config.id}"
  max_size             = 3
  min_size             = 1
  name                 = "kube-basic-worker"
  vpc_zone_identifier  = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

  tag {
    key                 = "Name"
    value               = "kube-basic-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

  depends_on = [
    "aws_eks_cluster.kube",
    "aws_launch_configuration.worker_launch_config"
  ]
}
resource "aws_autoscaling_group" "spot_worker_autoscaling_group" {
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.spot_worker_launch_config.id}"
  max_size             = 3
  min_size             = 1
  name                 = "kube-spot-worker"
  vpc_zone_identifier  = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

  tag {
    key                 = "Name"
    value               = "kube-spot-worker"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

  depends_on = [
    "aws_eks_cluster.kube",
    "aws_launch_configuration.spot_worker_launch_config"
  ]
}
