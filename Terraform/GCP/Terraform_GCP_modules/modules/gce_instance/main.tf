resource "google_compute_instance" "gce_instance" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  desired_status = var.vm_status

  labels = var.vm_labels

  dynamic "guest_accelerator"{
    for_each  = var.use_gpu_accelerator ? [1] : []
    content {
      type  = var.gpu_type
      count = var.gpu_cnt
    }
  }

  boot_disk {
    auto_delete = var.boot_disk_auto_delete
    initialize_params {
      image = var.boot_disk_image != null ? var.boot_disk_image : null
      snapshot = var.boot_disk_snapshot != null && var.boot_disk_image == null ? var.boot_disk_snapshot : null
      size  = var.boot_disk_size
      type  = var.boot_disk_type
      labels = var.boot_disk_labels     
    }
  }

  dynamic "attached_disk" {
    for_each = var.enable_additional_disks ? var.additional_disks : []
    content {
      source = attached_disk.value
      mode   = "READ_WRITE"
    }
  }

  network_interface {
    network    = var.network 
    subnetwork = var.subnetwork 
    network_ip = var.internal_ip
    dynamic "access_config" {
      for_each = var.use_external_ip ? [1] : []
      content {
	      	network_tier = var.external_ip_tier
     }
    }
  }
  
  tags = var.network_tags

  dynamic "service_account" {
  for_each = var.service_scope == "selected" ? [1] : [1]
    content {
        email  = var.service_account
        scopes = var.service_scope == "selected" ? var.service_scope_list : var.default_scope_list
     }
  }
  
  scheduling {
    automatic_restart   = var.auto_restart
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }


}

