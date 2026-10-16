output "worker" {
  description = "Complete Worker metadata."
  value       = module.worker.worker
}
output "deployment" {
  description = "Managed deployment and traffic allocation."
  value       = module.worker.deployment
}
output "domains" {
  description = "Managed custom domains."
  value       = module.worker.domains
}
