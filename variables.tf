variable "region" {
  # type = string
  default = "ap-southeast-2"
}

variable "cluster-name" {
  # type = string
  default = "kube"
}

variable "ami-id" {
  # type = string
  default = "ami-09f2d86f2d8c4f77d"
}

variable "key-name" {
  default = "erlang"
}

variable "min-nodes" {
  default = 4
}

variable "max-nodes" {
  default = 20
}
