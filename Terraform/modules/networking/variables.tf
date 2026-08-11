variable "project_name" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "az_count" {
  type = number
}

variable "availability_zones" {
  description = "AZs to use, in order. Passed in from root - see root variables.tf for why this isn't a data source."
  type        = list(string)
}

variable "single_nat_gateway" {
  type = bool
}
