# Sample 3-Tier Web Application — AWS (eu-west-2)

Terraform root module that provisions a classic 3-tier architecture in a single
region (`eu-west-2` by default) using Amazon Linux 2 instances:

```
Internet
   │
   ▼
[ Web ALB ] (public subnets)
   │
   ▼
[ Web ASG - Amazon Linux 2 / httpd ] (public subnets)
   │
   ▼
[ Internal App ALB ] (app subnets, private)
   │
   ▼
[ App ASG - Amazon Linux 2 / python app on :8080 ] (app subnets, private)
   │
   ▼
[ RDS MySQL ] (db subnets, private, not publicly accessible)
```

## Folder structure

```
terraform-3tier-aws/
├── main.tf                  # wires modules together
├── variables.tf              # root input variables (with sensible defaults)
├── outputs.tf                 # root outputs (ALB DNS names, RDS endpoint)
├── providers.tf                # AWS provider + required_providers
├── backend.tf                   # remote state config placeholder (S3, commented out)
├── terraform.tfvars.example      # copy to terraform.tfvars and customize
├── .gitignore
└── modules/
    ├── networking/            # VPC, public/app/db subnets, IGW, NAT, route tables
    ├── web-tier/                # Public ALB + ASG (Amazon Linux 2, httpd)
    ├── app-tier/                  # Internal ALB + ASG (Amazon Linux 2, sample app on :8080)
    └── database/                   # RDS instance + subnet group + security group
```

## Network layout

- 1 VPC (`10.0.0.0/16` by default)
- Public subnets (one per AZ) — hold the web ALB and web tier instances
- App subnets (private, one per AZ) — hold the internal ALB and app tier instances, reach
  the internet outbound via NAT Gateway
- DB subnets (private, one per AZ) — hold RDS only, no direct internet route

Security groups are scoped tier-to-tier: the internet can only reach the web
ALB on port 80; web instances only accept traffic from the web ALB; the app
ALB only accepts traffic from web instances; app instances only accept
traffic from the app ALB; RDS only accepts traffic from app instances.

## Usage

```bash
cd terraform-3tier-aws
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars (or export TF_VAR_db_password instead of putting it in the file)

terraform init
terraform plan
terraform apply
```

After apply, `terraform output web_alb_dns_name` gives you the public URL to browse to.

## Notes / things to adjust before using this beyond testing

- **Credentials**: this config expects AWS credentials to already be available to the
  provider (environment variables, `~/.aws/credentials`, or an HCP Terraform workspace
  variable set) — none are hardcoded here.
- **db_password**: has no default on purpose. Set it via `TF_VAR_db_password` or
  `-var`, never commit it in a `.tfvars` file.
- **State**: defaults to local state. Uncomment the S3 backend block in `backend.tf`
  once you have a state bucket + DynamoDB lock table.
- **single_nat_gateway**: defaults to `true` (one shared NAT Gateway) to keep costs
  down for testing. Set to `false` for one NAT Gateway per AZ in production.
- **ssh_allowed_cidr**: defaults to `0.0.0.0/0` for convenience while testing — restrict
  this to your own IP/CIDR (or remove the SSH ingress rule) for anything beyond a
  quick test.
- **App tier sample app**: the app tier launch template starts a trivial Python
  HTTP server on port 8080 as a placeholder — swap the `user_data` in
  `modules/app-tier/main.tf` for your real deployment method (AMI baked with your
  app, CodeDeploy, containers, etc).
- **HTTPS**: only HTTP listeners are configured. Add an ACM certificate + HTTPS
  listener on the web ALB for anything beyond local testing.
