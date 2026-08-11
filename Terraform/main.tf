module "network" {
  source = "./modules/network"

  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
}

module "database" {
  source = "./modules/database"

  project_name       = var.project_name
  db_name            = var.db_name
  db_username        = var.db_username
  db_password        = var.db_password
  subnet_ids         = module.network.database_subnet_ids
  database_sg_id     = module.security.database_sg_id
}

module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
}

module "compute" {
  source = "./modules/compute"

  project_name        = var.project_name
  vpc_id              = module.network.vpc_id
  public_subnet_ids   = module.network.public_subnet_ids
  private_subnet_ids  = module.network.private_app_subnet_ids
  web_sg_id           = module.security.web_sg_id
  alb_sg_id           = module.security.alb_sg_id
  target_port         = 80
  instance_type       = "t3.micro"
}
