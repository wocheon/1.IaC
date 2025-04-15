provider "google" {
	project = var.project
	region = var.region
}


resource "google_compute_snapshot" "disk_snapshot" {
	name 		= var.snapshot_name
	source_disk 	= var.source_disk
	zone 		= var.source_disk_zone
	storage_locations = [var.region]
}

resource "google_compute_disk" "new_disk_from_snapshot" {
	name		= var.new_disk_name
	zone		= var.new_disk_zone
	type		= var.new_disk_type
	size		= var.new_disk_size

	snapshot	= google_compute_snapshot.disk_snapshot.id
}
