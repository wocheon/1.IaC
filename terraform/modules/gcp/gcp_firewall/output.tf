output "firewall_rule_names" {
  description = "Names of created firewall rules"
  value       = [for fw in google_compute_firewall.firewall : fw.name]
}

output "firewall_rule" {  
  value = {
    for k, rules in google_compute_firewall.firewall : k => {
      name                = rules.name
      allow               = rules.allow
      source_ranges       = rules.source_ranges
      target_tags         = rules.target_tags
    }
  }
}