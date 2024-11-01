variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
}

variable "region" {
  description = "GCP 리전"
  type        = string
}

variable "zone" {
  description = "GCP 존"
  type        = string
}

variable "active_vm_name" {
  description = "Active VM 이름"
  type        = string
}

variable "active_vm_disk" {
  description = "Active VM의 디스크 이름"
  type        = string
}

variable "backup_vm_name" {
  description = "백업 VM 이름"
  type        = string
}

variable "disk_size" {
  description = "디스크 크기 (GB)"
  type        = number
  default     = 150
}

variable "disk_type" {
  description = "디스크 타입"
  type        = string
  default     = "pd-standard"
}

