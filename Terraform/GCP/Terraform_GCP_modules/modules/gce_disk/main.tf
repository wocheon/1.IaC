resource "google_compute_disk" "gce_disk" {
        name            = var.new_disk_name
        zone            = var.new_disk_zone
        type            = var.new_disk_type
        size            = var.new_disk_size
        labels          = var.new_disk_labels
        image = var.new_disk_image_id != null ? var.new_disk_image_id : null
        snapshot = var.new_disk_snapshot_id != null && var.new_disk_image_id == null ? var.new_disk_snapshot_id : null
}
