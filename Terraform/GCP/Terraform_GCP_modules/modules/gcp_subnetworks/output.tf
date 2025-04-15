output "subnetworks" {
  description = "Created subnetworks with their secondary IP ranges."
  value = {
    for k, subnet in google_compute_subnetwork.subnetworks : k => {
      name                = subnet.name
      ip_cidr_range       = subnet.ip_cidr_range
      region              = subnet.region
      secondary_ip_ranges = subnet.secondary_ip_range
    }
  }
}
