resource "aws_eip" "this" {
  domain                 = var.aws_eip_domain
  network_border_group   = var.aws_eip_network_border_group
  public_ipv4_pool       = var.aws_eip_public_ipv4_pool

  tags = merge(
    {
      Name = var.aws_eip_name
    },
    var.aws_eip_tags
  )
}
