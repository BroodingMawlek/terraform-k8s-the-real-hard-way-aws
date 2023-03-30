# SecurityGroups
resource "aws_security_group" "bastion-lb" {
  name_prefix = "bastion-lb-"
  description = "Bastion-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-bastion-lb"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-public-lb" {
  name_prefix = "master-public-lb-"
  description = "Master-Public-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-public"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master-private-lb" {
  name_prefix = "master-private-lb-"
  description = "Master-Private-LB"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-master-lb-private"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "bastion" {
  name_prefix = "bastion-"
  description = "Bastion"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-bastion"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "etcd" {
  name_prefix = "etcd-"
  description = "etcd"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-etcd"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "master" {
  name_prefix = "k8s-master-"
  description = "K8s Master"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-k8s-master"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "worker" {
  name_prefix = "k8s-worker-"
  description = "K8s Worker"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name    = "${var.project}-k8s-worker"
    Project = var.project
    Owner   = var.owner
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group rules to add to above SecurityGroups

## Ingress
resource "aws_security_group_rule" "ssh" {
  for_each = {
    "Etcd"    = aws_security_group.etcd.id,
    "Masters" = aws_security_group.master.id,
    "Workers" = aws_security_group.worker.id,
  }
  security_group_id        = each.value
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  description              = "SSH: Bastion - ${each.key}"
}

### Bastion Host
resource "aws_security_group_rule" "allow_ingress_on_bastion_kubectl" {
  for_each = {
    "MasterPrivateLB" = aws_security_group.master-private-lb.id,
    "Masters"         = aws_security_group.master.id,
    "Workers"         = aws_security_group.worker.id
  }
  security_group_id        = each.value
  type                     = "ingress"
  from_port                = 6443 # beginning of range
  to_port                  = 6443 # end of range
  protocol                 = "tcp" # set
  source_security_group_id = aws_security_group.bastion.id # source
  description              = "kubectl: Bastion - ${each.key}"
}

resource "aws_security_group_rule" "allow_ingress_bastion-lb_on_bastion_ssh" {
  security_group_id        = aws_security_group.bastion.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion-lb.id
  description              = "SSH: Bastion-LB - Bastion"
}

### Bastion LB
resource "aws_security_group_rule" "allow_ingress_workstation_on_bastion-lb_ssh" {
  security_group_id = aws_security_group.bastion-lb.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "SSH: Workstation - MasterPublicLB"
}

### MasterPublicLB
resource "aws_security_group_rule" "allow_ingress_workstation_on-master-public-lb_kubectl" {
  security_group_id = aws_security_group.master-public-lb.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "kubectl: Workstation - MasterPublicLB"
}

### MasterPrivateLB
resource "aws_security_group_rule" "allow_ingress_on_master-private-lb_kubeapi" {
  security_group_id = aws_security_group.master-private-lb.id
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
#  cidr_blocks       = ["0.0.0.0/0"]
  cidr_blocks       = ["9.23.0.0/16"]
  description       = "kubeapi: ALL - MasterPrivateLB"
}

### etcd
resource "aws_security_group_rule" "allow_etcd" {
  for_each = {
    "Masters" = aws_security_group.master.id,
    "Etcd"    = aws_security_group.etcd.id
  }
  security_group_id        = aws_security_group.etcd.id
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2380
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "etcd: ${each.key} - Etcds"
}

### Master
resource "aws_security_group_rule" "allow_kubectl_on_master" {
  for_each = {
    "MasterPublicLB"  = aws_security_group.master-public-lb.id,
    "MasterPrivateLB" = aws_security_group.master-private-lb.id,
    "Workers"         = aws_security_group.worker.id
  }
  security_group_id        = aws_security_group.master.id
  type                     = "ingress"
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
  source_security_group_id = each.value
  description              = "kubectl: ${each.key} - Masters"
}

resource "aws_security_group_rule" "allow_ingress_worker_on_master_all" {
  security_group_id        = aws_security_group.master.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = aws_security_group.worker.id
  description              = "ALL: Workers - Masters"
}

### Worker
resource "aws_security_group_rule" "allow_ingress_on_worker_all" {
  for_each = {
    "Masters"         = aws_security_group.master.id,
    "MasterPrivateLB" = aws_security_group.master-private-lb.id
  }
  security_group_id        = aws_security_group.worker.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "all"
  source_security_group_id = each.value
  description              = "ALL: ${each.key} - Workers"
}

## Egress
resource "aws_security_group_rule" "egress_all" {
  for_each = {
    "BastionLB"       = aws_security_group.bastion-lb.id,
    "MasterPublicLB"  = aws_security_group.master-public-lb.id,
    "MasterPrivateLB" = aws_security_group.master-private-lb.id,
    "Bastion"         = aws_security_group.bastion.id,
    "Etcds"           = aws_security_group.etcd.id,
    "Masters"         = aws_security_group.master.id,
    "Workers"         = aws_security_group.worker.id
  }
  security_group_id = each.value
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Egress ALL: ${each.key}"
}
