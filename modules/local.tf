locals {
  workstation-external-cidr = "${chomp(data.http.workstation-external-ip.body)}/32"
}