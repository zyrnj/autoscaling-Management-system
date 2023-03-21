module "mynetwork" {

  source               = "./module"
  cidr                 = "10.0.0.0/16"
  availability_zone_names = ["us-east-1a","us-east-1b","us-east-1c","us-east-1d"]
  public_subnet_cidrs  = ["10.0.1.0/24"]
  private_subnet_cidrs = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"]
  dev-ami              = "ami-0b08abd0a1d4e0d83"
  provider_profile     = "demo"
}

