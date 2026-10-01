provider "google" {
  project = "test-project"
  region  = "asia-northeast3"
}

resource "google_compute_instance" "example" {
  name         = "db1"
  machine_type = "e2-small"
  zone         = "asia-northeast3-a"
  desired_status = "TERMINATED"
  

  boot_disk {
    initialize_params {
      image = "https://www.googleapis.com/compute/v1/projects/test-project/global/images/centos-mariadb-image"
      size  = 20
      type  = "pd-standard"
      labels = {
        type = "gce-boot-disk"
        user = "wocheon07"
      }
    }
  }

  network_interface {
    network    = "https://www.googleapis.com/compute/v1/projects/test-project/global/networks/test-vpc-1"
    subnetwork = "https://www.googleapis.com/compute/v1/projects/test-project/regions/asia-northeast3/subnetworks/test-vpc-sub-01"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  service_account {
    email  = "487401709675-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  labels = {
    type  = "gcevm"
    usage = "test-db"
    user  = "wocheon07"
    provider  = "terraform"
  }

  tags = []
}
