resource "aws_iam_instance_profile" "worker_profile" {
  name = "${var.cluster-name}_aws_worker_profile"
  role = "${aws_iam_role.eks_worker_role.name}"
}

locals {
  worker-userdata = <<USERDATA
#!/bin/bash
set -o xtrace
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.kube.endpoint}' --b64-cluster-ca '${aws_eks_cluster.kube.certificate_authority.0.data}' '${var.cluster-name}'
USERDATA
}

resource "aws_launch_template" "worker_launch_template" {
  name          = "${var.cluster-name}_worker_launch_template"
  description   = "Launch template for worker nodes"
  instance_type = "t3.medium"
  image_id      = "${var.ami-id}"
  user_data     = "${base64encode(local.worker-userdata)}"
  key_name      = "${var.key-name}"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = ["${aws_security_group.worker.id}"]
    delete_on_termination       = true
  }

  iam_instance_profile {
    name = "${aws_iam_instance_profile.worker_profile.name}"
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name                = "${var.cluster-name}_kube-spot-worker"
  desired_capacity    = tonumber("${var.min-nodes}")
  min_size            = tonumber("${var.min-nodes}")
  max_size            = tonumber("${var.max-nodes}")
  vpc_zone_identifier = ["${aws_subnet.primary.id}", "${aws_subnet.secondary.id}"]

  mixed_instances_policy {
    instances_distribution {
      on_demand_base_capacity                  = 2
      on_demand_percentage_above_base_capacity = 0
    }

    launch_template {
      launch_template_specification {
        launch_template_id = "${aws_launch_template.worker_launch_template.id}"
      }

      override {
        instance_type = "t3.large"
      }

      override {
        instance_type = "m4.large"
      }

      override {
        instance_type = "c4.large"
      }
    }
  }

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

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = ""
    propagate_at_launch = false
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
    value               = ""
    propagate_at_launch = false
  }

  depends_on = [
    "aws_eks_cluster.kube",
    "aws_launch_template.worker_launch_template"
  ]
}
