resource "aws_vpc" "kube" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
      "Name", "kube vpc",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_internet_gateway" "kube" {
  vpc_id = "${aws_vpc.kube.id}"

  tags = {
    Name = "kube internet gateway"
  }
}

resource "aws_route_table" "kube" {
  vpc_id = "${aws_vpc.kube.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.kube.id}"
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "primary" {
  vpc_id                  = "${aws_vpc.kube.id}"
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags = "${
    map(
      "Name", "kube primary subnet",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_route_table_association" "primary-association" {
  subnet_id      = "${aws_subnet.primary.id}"
  route_table_id = "${aws_route_table.kube.id}"
}

resource "aws_subnet" "secondary" {
  vpc_id                  = "${aws_vpc.kube.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags = "${
    map(
      "Name", "kube secondary subnet",
      "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_route_table_association" "secondary-association" {
  subnet_id      = "${aws_subnet.secondary.id}"
  route_table_id = "${aws_route_table.kube.id}"
}

resource "aws_security_group" "kube" {
  name        = "kube security group"
  description = "Used with eks and workers"
  vpc_id      = "${aws_vpc.kube.id}"

  # inbount access from anywhere
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "worker" {
  name        = "worker security group"
  description = "Used with eks and workers"
  vpc_id      = "${aws_vpc.kube.id}"

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
      "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "worker-talk-to-self" {
  description              = "Allow nodes to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.worker.id}"
  source_security_group_id = "${aws_security_group.worker.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "worker-talk-to-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.worker.id}"
  source_security_group_id = "${aws_security_group.kube.id}"
  to_port                  = 65535
  type                     = "ingress"
}