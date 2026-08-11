variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "web_sg_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "target_port" {
  type = number
}

variable "instance_type" {
  type = string
}
