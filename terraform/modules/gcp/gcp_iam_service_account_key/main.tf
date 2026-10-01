resource "google_service_account_key" "this" {
  service_account_id = var.service_account_id
  keepers = {
    service_account_email = var.service_account_email
  }
}

resource "local_file" "sa_key_file" {
  content  = base64decode(google_service_account_key.this.private_key)
  filename = "${path.root}/${var.service_account_id}.json"
  directory_permission = "0700"
  file_permission      = "0700"
}