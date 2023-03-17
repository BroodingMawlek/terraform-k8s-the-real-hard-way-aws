# Data sources
## Ubuntu AMI for all K8s instances
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

## Amazon Linux AMI for Bastion Host
data "aws_ami" "amazonlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

}

## AWS region's Availabililty Zones
data "aws_availability_zones" "available" {
  state = "available"
}

## Get local workstation's external IPv4 address
data "http" "workstation-external-ip" {
  url = "http://ipv4.icanhazip.com"
}

## Route53 HostedZone ID from name
data "aws_route53_zone" "selected" {
  name         = "${var.hosted_zone}."
  private_zone = false
}