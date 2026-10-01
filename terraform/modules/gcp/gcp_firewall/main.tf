resource "google_compute_firewall" "firewall" {
  for_each = { for rule in var.firewall_rules : rule.name => rule }

  name    = each.value.name
  network = var.network_self_link

  allow {
    protocol = each.value.protocol
    ports    = each.value.ports
  }

  direction     = each.value.direction
  priority      = each.value.priority
  source_ranges = each.value.source_ranges

  target_tags   = each.value.target_tags
}
