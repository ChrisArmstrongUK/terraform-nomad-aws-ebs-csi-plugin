output "plugin_id" {
  value       = var.plugin_id
  description = "The plugin id"
}

output "plugin_node_job_name" {
  value       = local.plugin_node_job_name
  description = "The name of the plugin nodes job"
}

output "plugin_controller_job_name" {
  value       = local.plugin_controller_job_name
  description = "The name of the plugin controller job"
}