resource "google_compute_subnetwork" "subnetworks" {
  for_each = { for subnet in var.subnetworks : subnet.name => subnet }

  name          = each.value.name
  ip_cidr_range = each.value.ip_cidr_range
  region        = each.value.region
  network       = var.network_self_link

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_cidr_ranges != null ? each.value.secondary_ip_cidr_ranges : []
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}
