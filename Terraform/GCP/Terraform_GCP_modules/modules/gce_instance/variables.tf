### GCP Project&Region ###

variable "zone" {
  type        = string
}

variable "service_account" {
  type        = string  
}

### VM General Configurations ###

variable "vm_name" {
  type        = string
}

variable "machine_type" {
  type        = string
}

variable "vm_status" {
  type        = string
  default     = "RUNNING"
}

variable "auto_restart" {
  type        = bool
  default     = true
}

variable "vm_labels" {
  type        = map(string)
}

### GPU Configurations ###

variable "use_gpu_accelerator" {
  type		= bool
  default	= false
}

variable "gpu_type" {
  type		= string
  default	= ""
}

variable "gpu_cnt" {
  type         = number
  default      = 0
}

### BOOT_DISK Configurations ###

variable "boot_disk_image" {
  type        = string
}

variable "boot_disk_snapshot" {
  type        = string
}

variable "boot_disk_size" {
  type        = number
}

variable "boot_disk_type" {
  type        = string
}

variable "boot_disk_auto_delete" {
  type        = bool
  default     = true
}

variable "boot_disk_labels" {
  type        = map(string)
}

### Additional_disk Configurations ###

variable "enable_additional_disks" {
  type        = bool
  default     = false
}

variable "additional_disks" {
  type    = list(string)
  default = []  
}

### Network Configurations ###

variable "network" {
  type        = string
}
variable "subnetwork" {
  type        = string
}
variable "internal_ip" {
  type        = string
}

variable "use_external_ip" {
  type        = bool
  default     = true
}

variable "external_ip_tier" {
  type        = string
  default     = "STANDARD"
}

variable "network_tags" {
  type        = list(string)
}

### Service_Account Scopes ### 

variable "service_scope" {  
  type        = string  
}

variable "service_scope_list" {
  type        = list(string)
}

variable "default_scope_list" {
  type        = list(string)
  default     = [
   "https://www.googleapis.com/auth/devstorage.read_only",
   "https://www.googleapis.com/auth/logging.write",
   "https://www.googleapis.com/auth/monitoring.write",
   "https://www.googleapis.com/auth/service.management.readonly",
   "https://www.googleapis.com/auth/servicecontrol",
   "https://www.googleapis.com/auth/trace.append"
  ]  
}

