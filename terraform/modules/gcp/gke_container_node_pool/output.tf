output "node_pool_names" {
  description = "Names of the created node pools"
  value       = [for pool in google_container_node_pool.pools : pool.name]
}

output "node_pool_versions" {
  description = "Kubernetes versions of the node pools"
  value       = [for pool in google_container_node_pool.pools : pool.version]
}

output "node_pool_autoscaling" {
  description = "Autoscaling configurations of the node pools"
  value       = [for pool in google_container_node_pool.pools : pool.autoscaling]
}

output "node_pool_machine_types" {
  description = "Machine types of the node pools"
  value = flatten([
    for pool in google_container_node_pool.pools : [
      for config in pool.node_config : config.machine_type
    ]
  ])
}
