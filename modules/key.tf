# AWS Key Pair to generate
# => If you want to use an existing AWS Key Pair one, set value for TF var.aws_key_pair_name
resource "aws_key_pair" "ssh" {
  count      = var.aws_key_pair_name == null ? 1 : 0
  key_name   = "${var.owner}-${var.project}"
  public_key = file(var.ssh_public_key_path)
}