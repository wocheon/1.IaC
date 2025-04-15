### GCP Project&Region ###

variable "project" {
  type        = string
  default     = "gcp-in-ca"
}

variable "region" {
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  type        = string
  default     = "asia-northeast3-a"
}

### Snapshot Configurations ###

variable "source_disk" {
  type        	= string
  default 	= "gcp-ansible-test"	
}

variable "source_disk_zone" {
  type        	= string
  default 	= "asia-northeast3-a"	
}

variable "snapshot_name" {
  type        	= string
  default	= "gcp-ansible-test-snapsht"	
}

### disk Configurations ###

variable "new_disk_name" {
  type	        = string
  default	= "testdisk-001"	
}

variable "new_disk_zone" {
  type	        = string
  default 	= "asia-northeast3-a"	
}

variable "new_disk_type" {
  type	        = string
  default	= "pd-standard"	
}

variable "new_disk_size" {
  type	        = number
  default	= 30 
}
