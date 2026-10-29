module "network" {
  source = "./network"

  project_name        = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
  admin_cidrs         = var.admin_cidrs
}

# The compute module (3 EC2 instances) is added here by task T07:
# module "compute" {
#   source = "./compute"
#   ...uses module.network outputs: subnet IDs and security group IDs
# }
