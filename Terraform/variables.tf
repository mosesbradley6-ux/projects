variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used to prefix/tag all resources"
  type        = string
  default     = "sample3tier"
}

variable "environment" {
  description = "Environment name (e.g. dev, test, prod)"
  type        = string
  default     = "test"
}

# --- Networking ---

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread subnets across"
  type        = number
  default     = 2
}

variable "availability_zones" {
  description = <<-EOT
    AZs to use, in order. Some sandbox/training accounts attach a Service
    Control Policy that explicitly denies ec2:DescribeAvailabilityZones, which
    breaks the usual `data "aws_availability_zones"` lookup. Supplying the
    list directly avoids that API call entirely. Defaults cover us-east-1;
    change these if you deploy to a different region.
  EOT
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "single_nat_gateway" {
  description = "Use one NAT Gateway for all AZs (cheaper, less resilient) instead of one per AZ"
  type        = bool
  default     = true
}

# --- AMI ---

variable "amazon_linux_2_ami_id" {
  description = <<-EOT
    AMI ID for Amazon Linux 2 (x86_64, HVM) to use for both the web and app
    tier instances. Some sandbox/training accounts attach a Service Control
    Policy that explicitly denies ssm:GetParameter, which breaks the usual
    `data "aws_ssm_parameter"` lookup of the "latest" AMI. Supplying the ID
    directly avoids that API call entirely.

    Find a current one via the EC2 console: Launch Instance -> search
    "Amazon Linux 2 AMI" -> copy the AMI ID shown for your region. Or, if
    ec2:DescribeImages is NOT blocked in your account:
      aws ec2 describe-images --owners amazon \
        --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" \
                  "Name=state,Values=available" \
        --query "reverse(sort_by(Images, &CreationDate))[:1].ImageId" \
        --region us-east-1 --output text
  EOT
  type        = string
  default     = "ami-0bdc7d025135d7b49"
}

# --- Web tier (public-facing ALB + ASG) ---

variable "web_instance_type" {
  description = "Instance type for web tier EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "web_asg_min_size" {
  type    = number
  default = 2
}

variable "web_asg_max_size" {
  type    = number
  default = 4
}

variable "web_asg_desired_capacity" {
  type    = number
  default = 2
}

# --- App tier (internal ALB + ASG) ---

variable "app_instance_type" {
  description = "Instance type for app tier EC2 instances"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the application tier listens on"
  type        = number
  default     = 8080
}

variable "app_asg_min_size" {
  type    = number
  default = 2
}

variable "app_asg_max_size" {
  type    = number
  default = 4
}

variable "app_asg_desired_capacity" {
  type    = number
  default = 2
}

# --- Access ---

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access (leave empty to disable SSH key)"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR range allowed to SSH into instances (via bastion/VPN ideally, not 0.0.0.0/0)"
  type        = string
  default     = "0.0.0.0/0"
}

# --- Database ---

variable "db_engine" {
  description = "RDS engine"
  type        = string
  default     = "mysql"
}

variable "db_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username for the database"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the database. Pass via TF_VAR_db_password or a .tfvars file that is NOT committed to git."
  type        = string
  sensitive   = true
}

variable "db_multi_az" {
  description = "Whether to deploy RDS in Multi-AZ for high availability"
  type        = bool
  default     = false
}
