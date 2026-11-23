module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.20.0.0/19", "10.20.32.0/19", "10.20.64.0/19"]
  public_subnets   = ["10.20.96.0/22", "10.20.100.0/22", "10.20.104.0/22"]
  database_subnets = ["10.20.112.0/24", "10.20.113.0/24", "10.20.114.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }
}
