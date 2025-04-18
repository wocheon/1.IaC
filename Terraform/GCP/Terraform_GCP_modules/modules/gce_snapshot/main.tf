resource "google_compute_snapshot" "disk_snapshot" {
        name            = var.snapshot_name
        source_disk     = var.snapshot_source_disk
        zone            = var.snapshot_source_disk_zone
        storage_locations = [var.snapshot_storage_locations]
}
