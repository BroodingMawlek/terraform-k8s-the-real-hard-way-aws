terraform {

    required_version = ">= 0.12.1"

    backend "s3" {
    bucket = "k8s-the-right-hard-way-aws"
    key    = "k8s-the-right-hard-way-aws.tfstate"
    region = "eu-west-1"
    dynamodb_table = "terraform-state-lock-dynamo"
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



  resource "aws_dynamodb_table" "state-lock" {
  name = "k8s-the-right-hard-way-aws-lock"
  hash_key = "LockID"
  read_capacity = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }
}
