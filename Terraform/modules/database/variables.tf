variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "app_instance_security_group_id" {
  description = "Security group ID of the app tier instances, used to scope inbound access"
  type        = string
}

variable "engine" {
  type    = string
  default = "mysql"
}

variable "engine_version" {
  type    = string
  default = "8.0"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "username" {
  type      = string
  sensitive = true
}

variable "password" {
  type      = string
  sensitive = true
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "multi_az" {
  type    = bool
  default = false
}
