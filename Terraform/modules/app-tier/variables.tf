variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_subnet_ids" {
  type = list(string)
}

variable "web_instance_security_group_id" {
  description = "Security group ID of the web tier instances, used to scope inbound access"
  type        = string
}

variable "app_port" {
  type = number
}

variable "instance_type" {
  type = string
}

variable "key_name" {
  type    = string
  default = ""
}

variable "ssh_allowed_cidr" {
  type = string
}

variable "asg_min_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}

variable "asg_desired_capacity" {
  type = number
}
