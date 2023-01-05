module "ec2_instances" {
  source          = "./modules/EC2"
  ami-1           = var.ami-1
  ami-2           = var.ami-2
  instance_type-1 = var.instance_type-1
  instance_type-2 = var.instance_type-2
}