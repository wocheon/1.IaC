### GCP Project&Region ###
project       = "test-project"
region        = "asia-northeast3"
zone          = "asia-northeast3-a"


### VM General Configurations ###
#vm_name = "terraform-test"
vm_name = "db-test"
machine_type  = "e2-small"
vm_status = "RUNNING"
auto_restart = true

vm_labels = {
  type  = "gcevm"
  usage = "test-db"
  user  = "wocheon07"
  provider  = "terraform"
}

### Boot_disk Configurations ###

#boot_disk_image = "centos-mariadb-image"
#boot_disk_image = "ubuntu-2004-focal-v20240830"
#boot_disk_image = "ubuntu-2004-default-image"
boot_disk_image = "packer-image-240919"
boot_disk_size = 30	#number
boot_disk_type = "pd-standard"
boot_disk_auto_delete = true

boot_disk_labels = {
   type = "gce-boot-disk"
   user = "wocheon07"
}

### Network Configurations ###

network = "test-vpc-1"
subnetwork = "test-vpc-sub-01"
internal_ip = "192.168.1.102"

use_external_ip = true
external_ip_tier = "STANDARD"

network_tags = [
	"work",
	"terraform-test"
]

### Additional Disk Configurations ### 
enable_additional_disks = false

additional_disks = [
	{ name = "add-disk-1" 
          size_gb = 20 
          type = "pd-standard" 
        },
        { name = "add-disk-2"
          size_gb = 30
          type = "pd-standard"
        }
]
### Service Scpoes List ### 


service_scope = "default"

service_scope_list = [
  "https://www.googleapis.com/auth/cloud-platform",
  "https://www.googleapis.com/auth/compute",
  "https://www.googleapis.com/auth/devstorage.full_control",
  "https://www.googleapis.com/auth/cloud-platform" 
]

#default_scope_list = [
#   "https://www.googleapis.com/auth/devstorage.read_only",
#   "https://www.googleapis.com/auth/logging.write",
#   "https://www.googleapis.com/auth/monitoring.write",
#   "https://www.googleapis.com/auth/service.management.readonly",
#   "https://www.googleapis.com/auth/servicecontrol",
#   "https://www.googleapis.com/auth/trace.append"
#]
#

### Metadata SSH keys List ### 
ssh_keys_map = { 
   root = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsqnZAQKBtydbn040mWetqauZ6Kx+a7r5B4AH4gv2iPmRpSJdBsphKioxaeQ0F9+h5DMY5xfEQIW2PXc7UM9+we2OHf0pirgA1QTXPOoXBmd31Z1dMWMlIBIpXjoyLZ79XHRk9r0U7hoO9/zAUrG49csq+bfRPYZG8GtQcXnRa7mVeapTxIHeHmoiEXTOMx4qG/8iR/BfWjLn55RXXwHDHgq4pm+3NBCiZzV+EgMKLppP2tM4x6Dq8WZT5yxbTGjSypfYULiLB5dPLx2t3KuiCnQBRephhb9pzcrxQAeh7AHI5EmRs8o5W6bCK6iwTPmnRHqeIvWc9Xo2gJLqYXSZd root@gcp-ansible-test", 
   root = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHhM4DQehhz8K2sJUK9oYupjLCp1K3R7dLQB8rEn7W0oGQ7lozi8gSfL9PiOLdF0ldx5WuzMBC3iD6fqjO7rkMRV//16JmuKY64NSgsqR6O/7YO7ogdgvLvZ2zwtF0kvPs/9Ug9vevx39GgD4AeZlgLMoc2zBWgcmjhejl3bZlDdOO5YhhwK4HsIZhbSVvqBoP4yUcncrdefqIkd9ptO919gWMwSigq+MPgVIOz+slYYJfVnke42KOXYPAufwp8QZoyYJqrvlGy+Wzx1utQmrJS897jNXQaSxQRktBwZcMYKsEt6lCsdMNZN/LqXZ+WFQNukbw4+FcxKNYz6YXzooSlW6i3IJ0V8eIHbI3zW2gs0JnmPThpmlzs92O8P93GCE1hOs/dfmwxmLlUyAOcVOUWaFGzmE6PK+Fb8ryuz+EDClX1W2by35IxirBempkar50yOCcfnPPh+4j3E4aSzCWYNJruSHYPYJkRGtpjAD7WV0BQGmZDLXVHfQezdNXrgM= wocheon07@gmail.com"
}

