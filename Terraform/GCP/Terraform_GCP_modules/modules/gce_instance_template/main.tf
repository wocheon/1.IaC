resource "google_compute_instance_template" "this" {
  name            = var.new_template_name
  machine_type    = var.new_template_machine_type
  region = var.new_template_region != null ? var.new_template_region : null

  labels          = var.new_template_labels

  dynamic "guest_accelerator"{
    for_each  = var.use_gpu_accelerator ? [1] : []
    content {
      type  = var.new_template_gpu_type
      count = var.new_template_gpu_cnt
    }
  }

  disk {
    source_image = var.new_template_disk_source_image
    auto_delete  = var.new_template_disk_auto_delete
    boot         = true
    disk_size_gb = var.new_template_disk_size_gb
    disk_type    = var.new_template_disk_type
  }

  network_interface {
    network    = var.new_template_network 
    subnetwork = var.new_template_subnetwork     

    dynamic "access_config" {
      for_each = var.use_external_ip ? [1] : []
      content {
	      	network_tier = var.new_template_external_ip_tier
     }
    }
  }
  
  tags = var.new_template_network_tags

  dynamic "service_account" {
  for_each = var.service_scope == "selected" ? [1] : []
    content {
        email  = var.service_account
        scopes = var.service_scope == "selected" ? var.service_scope_list : var.default_scope_list
     }
  }
  
  scheduling {
    automatic_restart   = var.new_template_auto_restart
    on_host_maintenance = "MIGRATE"
    preemptible         = false    
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

}
