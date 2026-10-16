resource "terraform_data" "upstream" {
  input = {
    account_id = "0123456789abcdef0123456789abcdef"
    zone_id    = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    secret     = "unknown-until-apply"
    cron       = "0 * * * *"
  }
}
module "worker" {
  source            = "../../.."
  account_id        = terraform_data.upstream.output.account_id
  name              = "unknown-worker"
  create_version    = true
  create_deployment = true
  create_schedules  = true
  script = {
    compatibility_date = "2026-10-01"
    main_module        = "index.js"
    modules            = [{ name = "index.js", content_type = "application/javascript+module", content_base64 = base64encode("export default { fetch() { return new Response('ok'); } };") }]
    bindings           = [{ name = "TOKEN", type = "secret_text", text = terraform_data.upstream.output.secret }]
  }
  routes    = { api = { zone_id = terraform_data.upstream.output.zone_id, pattern = "example.com/*" } }
  domains   = { api = { zone_id = terraform_data.upstream.output.zone_id, hostname = "api.example.com" } }
  schedules = [terraform_data.upstream.output.cron]
}
output "route_keys" {
  description = "Known route keys for unknown-input plan assertions."
  value       = keys(module.worker.routes)
}
output "domain_keys" {
  description = "Known domain keys for unknown-input plan assertions."
  value       = keys(module.worker.domains)
}
