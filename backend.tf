terraform {
  backend "s3" {
    bucket                  = "turbo-terraform-demo"
    key                     = "state-demo/terraform.tfstate"
    region                  = "us-east-2"
    shared_credentials_file = "creds"
  }
}