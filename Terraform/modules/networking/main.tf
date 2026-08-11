# NOTE: No `data "aws_availability_zones" "available" {}` here on purpose.
# In sandbox/training accounts, ec2:DescribeAvailabilityZones is sometimes
# explicitly denied by an org-level SCP, which breaks that lookup. Instead
# we take the AZ list as an input variable from root (var.availability_zones)
# and just slice it down to az_count.

locals {
  azs = slice(var.availability_zones, 0, var.az_count)

  public_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i)]        # 10.0.0.0/24, 10.0.1.0/24, ...
  app_subnet_cidrs    = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 10)]    # 10.0.10.0/24, 10.0.11.0/24, ...
  db_subnet_cidrs     = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 8, i + 20)]    # 10.0.20.0/24, 10.0.21.0/24, ...
}

# --- VPC ---

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- Subnets ---

resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-${local.azs[count.index]}"
    Tier = "public"
  }
}

resource "aws_subnet" "app" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.app_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project_name}-app-${local.azs[count.index]}"
    Tier = "app"
  }
}

resource "aws_subnet" "db" {
  count             = var.az_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = local.db_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = {
    Name = "${var.project_name}-db-${local.azs[count.index]}"
    Tier = "db"
  }
}

# --- NAT Gateway(s) for the app subnets' outbound internet access ---

resource "aws_eip" "nat" {
  count  = var.single_nat_gateway ? 1 : var.az_count
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index}"
  }
}

resource "aws_nat_gateway" "this" {
  count         = var.single_nat_gateway ? 1 : var.az_count
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index}"
  }

  depends_on = [aws_internet_gateway.this]
}

# --- Route tables ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "app" {
  count  = var.az_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.this[0].id : aws_nat_gateway.this[count.index].id
  }

  tags = {
    Name = "${var.project_name}-app-rt-${count.index}"
  }
}

resource "aws_route_table_association" "app" {
  count          = var.az_count
  subnet_id      = aws_subnet.app[count.index].id
  route_table_id = aws_route_table.app[count.index].id
}

# DB subnets: no route to the internet at all (private, isolated).
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project_name}-db-rt"
  }
}

resource "aws_route_table_association" "db" {
  count          = var.az_count
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db.id
}
