output "worker" {
  description = "Worker metadata, including workers.dev status and URL."
  value       = module.worker.worker
}
output "version_id" {
  description = "Uploaded version ID."
  value       = module.worker.version_id
}
