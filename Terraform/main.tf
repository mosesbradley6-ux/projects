module "networking" {
  source = "./modules/networking"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  az_count            = var.az_count
  availability_zones  = var.availability_zones
  single_nat_gateway  = var.single_nat_gateway
}

module "web_tier" {
  source = "./modules/web-tier"

  project_name      = var.project_name
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids

  ami_id        = var.amazon_linux_2_ami_id
  instance_type = var.web_instance_type
  key_name      = var.key_name
  ssh_allowed_cidr = var.ssh_allowed_cidr

  asg_min_size         = var.web_asg_min_size
  asg_max_size         = var.web_asg_max_size
  asg_desired_capacity = var.web_asg_desired_capacity
}

module "app_tier" {
  source = "./modules/app-tier"

  project_name                   = var.project_name
  vpc_id                         = module.networking.vpc_id
  app_subnet_ids                 = module.networking.app_subnet_ids
  web_instance_security_group_id = module.web_tier.instance_security_group_id

  ami_id           = var.amazon_linux_2_ami_id
  app_port         = var.app_port
  instance_type    = var.app_instance_type
  key_name         = var.key_name
  ssh_allowed_cidr = var.ssh_allowed_cidr

  asg_min_size         = var.app_asg_min_size
  asg_max_size         = var.app_asg_max_size
  asg_desired_capacity = var.app_asg_desired_capacity
}

module "database" {
  source = "./modules/database"

  project_name                   = var.project_name
  vpc_id                          = module.networking.vpc_id
  db_subnet_ids                   = module.networking.db_subnet_ids
  app_instance_security_group_id  = module.app_tier.instance_security_group_id

  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  db_name           = var.db_name
  username          = var.db_username
  password          = var.db_password
  multi_az          = var.db_multi_az
}
