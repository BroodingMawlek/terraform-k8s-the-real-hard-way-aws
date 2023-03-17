# Load Balancer
## Bastion Host
resource "aws_elb" "bastion" {
  name_prefix     = "basti-" // cannot be longer than 6 characters
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.bastion-lb.id]

  listener {
    instance_port     = 22
    instance_protocol = "tcp"
    lb_port           = 22
    lb_protocol       = "tcp"
  }

  tags = {
    Name    = "${var.project}-bastion-lb"
    Project = var.project
    Owner   = var.owner
  }
}

## Kubernetes Master (for remote kubctl access from workstation)
resource "aws_elb" "master-public" {
  name_prefix     = "master" // cannot be longer than 6 characters
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.master-public-lb.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  tags = {
    Name      = "${var.project}-master--publiclb"
    Attribute = "public"
    Project   = var.project
    Owner     = var.owner
  }
}

## Kubernetes Master (fronting kube-apiservers)
resource "aws_elb" "master-private" {
  name_prefix     = "master" // will be prefixed with internal -  cannot be longer than 6 characters
  internal        = true
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.master-private-lb.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  tags = {
    Name     = "${var.project}-master--private-lb"
    ttribute = "private"
    Project  = var.project
    Owner    = var.owner
  }
}

# LaunchConfigurations
## Bastion Host
resource "aws_launch_configuration" "bastion" {
  name_prefix                 = "bastion-"
  image_id                    = data.aws_ami.amazonlinux.id
  instance_type               = var.bastion_instance_type
  security_groups             = [aws_security_group.bastion.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.bastion.id

  user_data = templatefile("${path.module}/../user-data/userdata-bastion.tpl", {
    component = "bastion"
    domain    = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}

## etcd
resource "aws_launch_configuration" "etcd" {
  name_prefix                 = "etcd-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.etcd_instance_type
  security_groups             = [aws_security_group.etcd.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.etcd_worker_master.id

  user_data = templatefile("${path.module}/../user-data/userdata.tpl", {
    domain = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}

## Kubernetes Master
resource "aws_launch_configuration" "master" {
  name_prefix                 = "master-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  security_groups             = [aws_security_group.master.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.etcd_worker_master.id

  user_data = templatefile("${path.module}/../user-data/userdata.tpl", {
    domain = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}

## Kubernetes Worker
resource "aws_launch_configuration" "worker" {
  name_prefix                 = "worker-"
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  security_groups             = [aws_security_group.worker.id]
  key_name                    = var.aws_key_pair_name == null ? aws_key_pair.ssh.0.key_name : var.aws_key_pair_name
  associate_public_ip_address = false
  ebs_optimized               = true
  enable_monitoring           = true
  iam_instance_profile        = aws_iam_instance_profile.etcd_worker_master.id

  user_data = templatefile("${path.module}/../user-data/userdata-worker.tpl", {
    pod_cidr = var.pod_cidr
    domain   = var.hosted_zone
  })

  lifecycle {
    create_before_destroy = true
  }
}


# AutoScalingGroups

## Bastion
resource "aws_autoscaling_group" "bastion" {
  max_size             = var.bastion_max_size
  min_size             = var.bastion_min_size
  desired_capacity     = var.bastion_size
  force_delete         = false
  launch_configuration = aws_launch_configuration.bastion.name
  vpc_zone_identifier  = aws_subnet.private.*.id
  load_balancers       = [aws_elb.bastion.id]


  tag  {
      key                 = "Name"
      value               = "${var.project}-bastion"
      propagate_at_launch = true
    }

  tag  {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    }

  tag  {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }

}

## etcd
resource "aws_autoscaling_group" "etcd" {
  max_size             = var.etcd_max_size
  min_size             = var.etcd_min_size
  desired_capacity     = var.etcd_size
  force_delete         = true
  launch_configuration = aws_launch_configuration.etcd.name
  vpc_zone_identifier  = aws_subnet.private.*.id

    tag  {
      key                 = "Name"
      value               = "${var.project}-etcd"
      propagate_at_launch = true
    }

  tag  {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    }

  tag  {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }



}

## Kubernetes Master
resource "aws_autoscaling_group" "master" {
  max_size             = var.master_max_size
  min_size             = var.master_min_size
  desired_capacity     = var.master_size
  force_delete         = true
  launch_configuration = aws_launch_configuration.master.name
  vpc_zone_identifier  = aws_subnet.private.*.id
  load_balancers       = [aws_elb.master-public.id, aws_elb.master-private.id]

  tag  {
      key                 = "Name"
      value               = "${var.project}-k8s-master"
      propagate_at_launch = true
    }

  tag  {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    }

  tag  {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }
}

## Kubernetes Worker
resource "aws_autoscaling_group" "worker" {
  max_size             = var.worker_max_size
  min_size             = var.worker_min_size
  desired_capacity     = var.worker_size
  force_delete         = true
  launch_configuration = aws_launch_configuration.worker.name
  vpc_zone_identifier  = aws_subnet.private.*.id


  tag  {
      key                 = "Name"
      value               = "${var.project}-k8s-worker"
      propagate_at_launch = true
    }

  tag  {
      key                 = "Project"
      value               = var.project
      propagate_at_launch = true
    }

  tag  {
      key                 = "Owner"
      value               = var.owner
      propagate_at_launch = true
    }

}
