provider "google" {
  project = var.project_id
  region  = var.region
}

# Active VM의 디스크 스냅샷 생성
resource "google_compute_snapshot" "active_vm_snapshot" {
  name        = "${var.active_vm_name}-disk-snapshot-${formatdate("YYYYMMDD", timestamp())}"
  source_disk = "projects/${var.project_id}/zones/${var.zone}/disks/${var.active_vm_disk}"
  zone        = var.zone
}

# 백업 VM 정보 가져오기
data "google_compute_instance" "backup_vm" {
  name = var.backup_vm_name
  zone = var.zone
}

# 스냅샷을 기반으로 백업 VM용 디스크 생성
resource "google_compute_disk" "backup_vm_new_disk" {
  name           = "${var.backup_vm_name}-disk-${formatdate("YYYYMMDD", timestamp())}"
  zone           = var.zone
  snapshot = google_compute_snapshot.active_vm_snapshot.self_link

  size = var.disk_size
  type = var.disk_type
}

# 백업 VM의 부팅 디스크를 gcloud 명령어로 변경
resource "null_resource" "update_backup_vm_disk" {
  provisioner "local-exec" {
    command = <<EOT
      # 기존 부팅 디스크의 전체 URL 가져오기
      OLD_DISK_URL=$(gcloud compute instances describe ${var.backup_vm_name} --zone ${var.zone} --format="value(disks[0].source)")
      
      # 전체 URL에서 디스크 이름 추출
      OLD_DISK_NAME=$(basename $OLD_DISK_URL)
      
      # 기존 부팅 디스크 분리
      gcloud compute instances detach-disk ${var.backup_vm_name} --zone ${var.zone} --disk $OLD_DISK_NAME
      
      # 새로운 부팅 디스크 연결
      gcloud compute instances attach-disk ${var.backup_vm_name} --zone ${var.zone} --disk ${google_compute_disk.backup_vm_new_disk.name} --boot
      
      # 기존 부팅 디스크 삭제
      gcloud compute disks delete $OLD_DISK_NAME --zone ${var.zone} --quiet
    EOT
  }

  depends_on = [google_compute_disk.backup_vm_new_disk]
}

