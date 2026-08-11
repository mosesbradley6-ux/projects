variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "ami_id" {
  description = "AMI ID to launch (passed in from root - see root variables.tf for why this isn't a data source)."
  type        = string
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
