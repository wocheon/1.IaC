provider "google" {
  project = var.project
  region  = var.region
}

resource "google_compute_disk" "additional" {
  count = var.enable_additional_disks ? length(var.additional_disks) : 0

  name  = var.additional_disks[count.index].name
  type  = var.additional_disks[count.index].type
  zone  = var.zone
  size  = var.additional_disks[count.index].size_gb
}


resource "google_compute_instance" "example" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  desired_status = var.vm_status

  labels = var.vm_labels

  boot_disk {
    auto_delete = var.boot_disk_auto_delete
    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
      labels = var.boot_disk_labels
    }
  }

  dynamic "attached_disk" {
    for_each = var.enable_additional_disks ? google_compute_disk.additional : []
    content {
      source = attached_disk.value.id
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

  dynamic "service_account" {
  for_each = var.service_scope == "selected" ? [1] : [1]
    content {
        email  = "xxxxxxxxxxxxx-compute@developer.gserviceaccount.com"
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


  tags = []
}
