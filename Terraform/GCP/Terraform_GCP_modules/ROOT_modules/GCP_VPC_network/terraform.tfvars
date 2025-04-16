### GCP Project&Region ###
project       = "gcp-in-ca"
region        = "asia-northeast3"

vpc_network_name = "terraform-test-vpc"

subnetworks = [
  {
    name          = "terraform-test-subnet-1"
    ip_cidr_range = "10.2.1.0/24"
    region        = "asia-northeast3"
    secondary_ip_cidr_ranges = [
      {
        range_name    = "gke-pods-range"
        ip_cidr_range = "10.10.0.0/16"
      }
    ]
  },
  {
    name          = "terraform-test-subnet-2"
    ip_cidr_range = "10.2.2.0/24"
    region        = "asia-northeast3"
    # secondary_ranges 없이도 가능    
  }
]


firewall_rules = [
  {
    name          = "terraform-test-vpc-allow-ssh"
    protocol      = "tcp"
    ports         = ["22"]
    direction     = "INGRESS"
    priority      = 1000
    source_ranges = ["0.0.0.0/0"]
    target_tags   = ["ssh-access"]
  },
  {
    name          = "terraform-test-vpc-allow-http"
    protocol      = "tcp"
    ports         = ["80"]
    direction     = "INGRESS"
    priority      = 1000
    source_ranges = ["0.0.0.0/0"]
    target_tags   = ["http-server"]
  }
]