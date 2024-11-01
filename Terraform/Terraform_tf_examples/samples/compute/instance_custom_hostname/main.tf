/**
 * Copyright 2022 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

# [START compute_instances_create_custom_hostname]

resource "google_compute_instance" "default" {
  project = "gcp-in-ca"
  name         = "terraform-test-vm"
  machine_type = "e2-micro"
  zone         = "asia-northeast3-c"
  desired_status = "RUNNING"

# Set a custom hostname below
#  hostname = "hashicorptest"

  boot_disk {
    initialize_params {
#      image = "debian-cloud/debian-11"
      image = "centos-mariadb-image"
    }
  }
  network_interface {
    # A default network is created for all GCP projects
    network = "test-vpc-1"
    subnetwork = "test-vpc-sub-01"
    subnetwork_project = "gcp-in-ca"
    network_ip = "192.168.1.102"
    access_config {
    }
  }
}

# [END compute_instances_create_custom_hostname]
