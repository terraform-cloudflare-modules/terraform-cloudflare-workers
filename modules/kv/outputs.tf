output "namespaces" {
  description = "Complete namespaces keyed by caller keys."
  value       = cloudflare_workers_kv_namespace.this
}

output "namespace_ids" {
  description = "Namespace IDs for Worker bindings."
  value       = { for key, namespace in cloudflare_workers_kv_namespace.this : key => namespace.id }
}

output "entries" {
  description = "Complete entries, including stored values. Sensitive."
  value       = cloudflare_workers_kv.this
  sensitive   = true
}
