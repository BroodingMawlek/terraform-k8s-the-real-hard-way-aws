# IAM Roles for EC2 Instance Profiles
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

# Bastion Host
data "aws_iam_policy_document" "bastion" {
  statement {
    sid = "bastion"
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:CreateRoute",
      "ec2:CreateTags",
      "ec2:DescribeAutoScalingGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers",
      "route53:ListHostedZonesByName"
    ]
    resources = ["*"]
  }

  statement {
    sid = "route53"
    actions = [
      "route53:ChangeResourceRecordSets"
    ]
    resources = [
      "arn:aws:route53:::hostedzone/${data.aws_route53_zone.selected.zone_id}"
    ]
  }
}

resource "aws_iam_role" "bastion" {
  name_prefix        = "bastion-"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "${var.project}-bastion"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "bastion" {
  name_prefix = "bastion-"
  role        = aws_iam_role.bastion.id
  policy      = data.aws_iam_policy_document.bastion.json
}

resource "aws_iam_instance_profile" "bastion" {
  name_prefix = "bastion-"
  role        = aws_iam_role.bastion.name
}

## etcd & Kubernetes instances
data "aws_iam_policy_document" "etcd_worker_master" {
  statement {
    sid = "autoscaling"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeTags",
      "elasticloadbalancing:DescribeLoadBalancers"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "etcd_worker_master" {
  name_prefix = "etcd-worker-master-"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name    = "${var.project}-etcd-worker-master"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy" "etcd_worker_master" {
  name_prefix = "etcd-worker-master-"
  role        = aws_iam_role.etcd_worker_master.id
  policy      = data.aws_iam_policy_document.etcd_worker_master.json
}

resource "aws_iam_instance_profile" "etcd_worker_master" {
  name_prefix = "etcd-worker-master-"
  role        = aws_iam_role.etcd_worker_master.name
}
