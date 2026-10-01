output "instance_template_self_link" {
  description = "생성된 인스턴스 템플릿의 self_link"
  value       = google_compute_instance_template.this.self_link
}

output "instance_template_name" {
  description = "생성된 인스턴스 템플릿 이름"
  value       = google_compute_instance_template.this.name
}
