# Uncomment these if you are using a public R53 record
#TODO document R53

## Route53
## Bastion Host
#resource "aws_route53_record" "bastion-public" {
#  zone_id = data.aws_route53_zone.selected.id
#  name    = "bastion"
#  type    = "A"
#
#  alias {
#    evaluate_target_health = false
#    name                   = aws_elb.bastion.dns_name
#    zone_id                = aws_elb.bastion.zone_id
#  }
#}
#
### Kubernetes Master for remote kubectl access
#resource "aws_route53_record" "master_lb-public" {
#  zone_id = data.aws_route53_zone.selected.id
#  name    = "kube"
#  type    = "A"
#
#  alias {
#    evaluate_target_health = false
#    name                   = aws_elb.master-public.dns_name
#    zone_id                = aws_elb.master-public.zone_id
#  }
#}


#TODO automate creation of hosted zone
#resource "aws_route53_zone" "this" {
#  name = var.hosted_zone
#    vpc {
#    vpc_id =
#  }
#
#}