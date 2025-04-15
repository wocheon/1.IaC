variable "new_template_name" {
  description = "생성할 인스턴스 템플릿 이름"
  type        = string
}

variable "new_template_region" {
  description = "생성할 인스턴스 템플릿 리전"
  type        = string
}

variable "new_template_machine_type" {
  description = "인스턴스 머신 타입 (e.g. e2-medium)"
  type        = string
}

variable "new_template_labels" {
  description = "템플릿에 적용할 라벨들"
  type        = map(string)
  default     = {}
}

variable "use_gpu_accelerator" {
  description = "GPU 가속기 사용 여부"
  type        = bool
  default     = false
}

variable "new_template_gpu_type" {
  description = "GPU 타입 (e.g. nvidia-tesla-t4)"
  type        = string
  default     = null
}

variable "new_template_gpu_cnt" {
  description = "GPU 개수"
  type        = number
  default     = 0
}

variable "new_template_disk_source_image" {
  description = "디스크 소스 이미지 (e.g. debian-cloud/debian-11)"
  type        = string
}

variable "new_template_disk_auto_delete" {
  description = "디스크 자동 삭제 여부"
  type        = bool
  default     = true
}

variable "new_template_disk_size_gb" {
  description = "디스크 크기 (GB)"
  type        = number
}

variable "new_template_disk_type" {
  description = "디스크 타입 (e.g. pd-standard, pd-ssd)"
  type        = string
}

variable "new_template_network" {
  description = "네트워크 이름"
  type        = string
}

variable "new_template_subnetwork" {
  description = "서브네트워크 이름"
  type        = string
}

variable "use_external_ip" {
  description = "External IP 사용 여부"
  type        = bool
  default     = true
}

variable "new_template_external_ip_tier" {
  description = "External IP 네트워크 티어 (e.g. PREMIUM)"
  type        = string
  default     = "PREMIUM"
}

variable "new_template_network_tags" {
  description = "네트워크 태그 리스트"
  type        = list(string)
  default     = []
}

variable "service_account" {
  description = "서비스 계정 이메일"
  type        = string
}

variable "service_scope" {
  description = "서비스 스코프 선택 (default 또는 selected)"
  type        = string
  default     = "default"
}

variable "service_scope_list" {
  description = "선택된 서비스 스코프 리스트"
  type        = list(string)
  default     = []
}

variable "default_scope_list" {
  description = "기본 서비스 스코프 리스트"
  type        = list(string)
  default     = [
    "https://www.googleapis.com/auth/cloud-platform"
  ]
}

variable "new_template_auto_restart" {
  description = "자동 재시작 여부"
  type        = bool
  default     = true
}
