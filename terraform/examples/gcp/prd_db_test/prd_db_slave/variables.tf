### GCP Project&Region ###

variable "project" {
  type        = string
  default     = "test-project"
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  type        = string
  default     = "asia-northeast3-a"
}

### VM General Configurations ###

variable "vm_name" {
  type        = string
}

variable "machine_type" {
  type        = string
  default     = "e2-micro"
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
  default     = { 
        type = "gce-boot-disk"
        user = "wocheon07"   
  } 
}


### BOOT_DISK Configurations ###

variable "boot_disk_image" {
  type        = string
}

variable "boot_disk_size" {
  type        = number
  default     = 20	
}

variable "boot_disk_type" {
  type        = string
  default     = "pd-standard"
}

variable "boot_disk_auto_delete" {
  type        = bool
  default     = true
}

variable "boot_disk_labels" {
  type        = map(string)
  default     = { 
        type = "gce-boot-disk"
        user = "wocheon07"   
  } 
}

### Network Configurations ###

variable "network" {
  type        = string
  default     = "test-vpc-1"
}
variable "subnetwork" {
  type        = string
  default     = "test-vpc-sub-1"
}
variable "internal_ip" {
  type        = string
  default     = "192.168.1.101"
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
  default     = [
   "dev",
   "terraform"
  ]
}

### Additional disk Configurations ### 

variable "enable_additional_disks" {
  type        = bool
  default     = false
}

variable "additional_disks" {
  description = "List of additional disks to create"
  type = list(object({
    name                          = string
    type                          = string
    size_gb                       = number
  }))
  default = []
}


### Service_Account Scopes ### 

variable "service_scope" {
  description = "Scope of permissions for the service account"
  type        = string
  default     = "default"
}

variable "service_scope_list" {
  description = "List of scopes to apply if service_scope is 'selected'"
  type        = list(string)
  default     = []
}

variable "default_scope_list" {
  description = "List of default scopes to apply if service_scope is 'default'"
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
