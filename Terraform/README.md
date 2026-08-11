# Terraform AWS 3-Tier Test Application

This is a beginner-friendly Terraform project that creates:

- VPC
- 2 public subnets
- 2 private application subnets
- 2 private database subnets
- Internet Gateway
- NAT Gateway
- Security groups
- RDS PostgreSQL database
- S3 bucket
- Application Load Balancer
- Auto Scaling Group with Amazon Linux web servers
- A simple 3-tier test layout

## Architecture

Internet -> ALB (public subnets) -> Web/App EC2 instances (private app subnets) -> RDS PostgreSQL (private DB subnets)

The S3 bucket is provisioned separately for application/object storage testing.

## Prerequisites

- Terraform >= 1.6
- AWS CLI
- An AWS account
- AWS credentials configured locally

## Run

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

To actually create resources:

```bash
terraform apply
```

To remove everything:

```bash
terraform destroy
```

## Important

This is a learning/test environment. It is not production hardened.

The default RDS password is intentionally supplied as a Terraform variable for simplicity. For production, use AWS Secrets Manager or another secret-management solution.

The NAT Gateway incurs AWS charges. RDS and EC2 also incur charges while running.
