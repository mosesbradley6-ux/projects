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
├── main.tf                       # wires modules together
├── variables.tf                  # root input variables (with sensible defaults)
├── outputs.tf                    # root outputs (ALB DNS names, RDS endpoint)
├── providers.tf                  # AWS provider + required_providers
├── backend.tf                    # remote state config placeholder (S3, commented out)
├── terraform.tfvars.example      # copy to terraform.tfvars and customize
├── .gitignore
└── modules/
    ├── networking/  # VPC, public/app/db subnets, IGW, NAT, route tables
    ├── web-tier/    # Public ALB + ASG (Amazon Linux 2, httpd)
    ├── app-tier/    # Internal ALB + ASG (Amazon Linux 2, sample app on :8080)
    └── database/    # RDS instance + subnet group + security group
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
# also set amazon_linux_2_ami_id - see "Sandbox / restricted accounts" below

terraform init
terraform plan
terraform apply
```

After apply, `terraform output web_alb_dns_name` gives you the public URL to browse to.

## Sandbox / restricted accounts (SCP-denied `DescribeAvailabilityZones` / `GetParameter`)

Some sandbox or training AWS accounts (e.g. Cloud Playground-style environments)
attach an org-level Service Control Policy that **explicitly denies**:

- `ec2:DescribeAvailabilityZones`
- `ssm:GetParameter`

An explicit `Deny` in an SCP always wins over any IAM allow, so the usual
Terraform patterns of looking these up dynamically
(`data "aws_availability_zones"` and `data "aws_ssm_parameter"` for the
"latest" Amazon Linux 2 AMI) fail with `AccessDeniedException` /
`UnauthorizedOperation`, even though the account otherwise has full EC2/ALB/ASG/RDS
permissions. This config avoids those two calls entirely and takes the values
as plain variables instead:

- `availability_zones` — defaults to `["eu-west-2a", "eu-west-2b", "eu-west-2c"]`.
  Only change this if you deploy somewhere other than `eu-west-2`.
- `amazon_linux_2_ami_id` — **no default, you must set this.** Find a current
  AMI ID for your region via the EC2 console (Launch Instance → search
  "Amazon Linux 2 AMI" → copy the AMI ID shown), or, if `ec2:DescribeImages`
  is *not* blocked in your account:
  ```bash
  aws ec2 describe-images --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2" \
              "Name=state,Values=available" \
    --query "reverse(sort_by(Images, &CreationDate))[:1].ImageId" \
    --region eu-west-2 --output text
  ```
  Set it in `terraform.tfvars`:
  ```hcl
  amazon_linux_2_ami_id = "ami-xxxxxxxxxxxxxxxxx"
  ```

If your account is *not* restricted by an SCP like this, you don't need to do
anything special — just set `amazon_linux_2_ami_id` once (there's
intentionally no default, since AMI IDs go stale and are account/region
specific) and everything else works as-is.

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
