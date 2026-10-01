output "binding_role" {
  description = "The role that was bound to the service account"
  value       = google_project_iam_member.iam_role_binding.role
}

output "binding_member" {
  description = "The member (service account) that was bound"
  value       = google_project_iam_member.iam_role_binding.member
}
