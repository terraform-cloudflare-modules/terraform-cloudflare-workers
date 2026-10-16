output "name" {
  description = "Worker name, including in existing-Worker mode. Null when disabled."
  value       = local.name
  precondition {
    condition     = !var.create || (var.account_id != null && var.name != null)
    error_message = "Enabled modules require account_id and name."
  }
  precondition {
    condition     = !var.create || var.create_worker || alltrue([for value in var.worker : value == null])
    error_message = "Worker metadata settings require create_worker = true."
  }
  precondition {
    condition     = !var.create || var.create_schedules || length(var.schedules) == 0
    error_message = "Schedules require create_schedules = true."
  }
}

output "worker" {
  description = "Complete managed Worker, including computed references and URLs. Null in existing-Worker mode."
  value       = one(cloudflare_worker.this)
}

output "version" {
  description = "Complete uploaded version. Sensitive because bindings, code, and asset tokens can contain secrets."
  value       = one(cloudflare_worker_version.this)
  sensitive   = true
}

output "version_id" {
  description = "Uploaded version ID, or null when version upload is disabled."
  value       = one(cloudflare_worker_version.this[*].id)
}

output "deployment" {
  description = "Complete managed deployment, or null when unmanaged."
  value       = one(cloudflare_workers_deployment.this)
}

output "routes" {
  description = "Complete route resources keyed by input keys."
  value       = cloudflare_workers_route.this
}

output "domains" {
  description = "Complete custom domain resources keyed by input keys."
  value       = cloudflare_workers_custom_domain.this
}

output "schedules" {
  description = "Complete cron trigger resource, or null when unmanaged."
  value       = one(cloudflare_workers_cron_trigger.this)
}
