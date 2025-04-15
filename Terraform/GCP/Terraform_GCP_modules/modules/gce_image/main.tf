# Source_Disk는 VM에 할당되지 않거나, 중지된 VM의 디스크만 가능
resource "google_compute_image" "gce_image" {
        name              = var.new_image_name
        source_disk     = var.new_image_source_disk != null ? var.new_image_source_disk : null      # Use Selflink
        source_snapshot = var.new_image_source_snapshot != null && var.new_image_source_disk == null ? var.new_image_source_snapshot : null    # Use Selflink
        storage_locations = [var.new_image_storage_locations]
}