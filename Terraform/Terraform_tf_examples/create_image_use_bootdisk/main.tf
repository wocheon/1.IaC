provider "google" {
  project = var.project
  region  = var.region
}


data "google_compute_instance" "existing_vm" {
	name = var.vm_name
	zone = var.zone
}

resource "google_compute_image" "disk_image" {
	name = var.image_name 
	source_disk = data.google_compute_instance.existing_vm.boot_disk[0].source # VM의 부트 디스크
	storage_locations = [var.region]
	description	= "Image use by ${var.vm_name} boot disk"
}
