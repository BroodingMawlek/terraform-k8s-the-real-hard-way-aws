terraform {

  backend "s3" {
    bucket         = "k8s-the-right-hard-way-aws"
    key            = "k8s-the-right-hard-way-aws.tfstate"
    region         = "eu-west-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=2.14"
    }
  }

}

# Configure the AWS Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
