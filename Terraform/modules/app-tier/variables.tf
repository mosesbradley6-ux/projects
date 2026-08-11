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
  description = "Security group ID of the web tier instances - allowed to reach this tier's internal ALB"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to launch (passed in from root - see root variables.tf for why this isn't a data source)."
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
