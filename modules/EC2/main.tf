resource "aws_instance" "terraform-demo-1" {
  ami                = var.ami-1
  instance_type      = var.instance_type-1
  key_name           = "ray-demo"

  user_data          = "${file("user-data-script.sh")}"

  tags               = {
    Name             = "terraform-demo-1"
    turbo_owner      = "Ray.Mileo@ibm.com"
    Terraform_Config = "https://github.com/turbonomic-integrations/terraform-demo/blob/main/terraform.tfvars::instance_type-1"
  }
}

resource "aws_instance" "terraform-demo-2" {
  ami                = var.ami-2
  instance_type      = var.instance_type-2
  key_name           = "ray-demo"

  user_data          = "${file("user-data-script.sh")}"
  
  tags               = {
    Name             = "terraform-demo-2"
    turbo_owner      = "Ray.Mileo@ibm.com"
    Terraform_Config = "https://github.com/turbonomic-integrations/terraform-demo/blob/main/terraform.tfvars::instance_type-2"
  }
}

resource "aws_instance" "jfabry-waste-test" {
  ami                = var.ami-2
  instance_type      = var.instance_type-4
  key_name           = "ray-demo"

  user_data          = "${file("user-data-script.sh")}"

  tags               = {
    Name             = "jfabry-waste-test"
    turbo_owner      = "tester@test.com"
    Terraform_Config = "https://github.com/turbonomic-integrations/terraform-demo/blob/main/terraform.tfvars::instance_type-3"
  }
}
