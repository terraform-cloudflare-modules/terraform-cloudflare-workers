resource "cloudflare_worker" "this" {
  count                = var.create && var.create_worker ? 1 : 0
  account_id           = var.account_id
  name                 = var.name
  force                = var.worker.force
  logpush              = var.worker.logpush
  observability        = var.worker.observability
  previews_base_config = var.worker.previews_base_config
  subdomain            = var.worker.subdomain
  tags                 = var.worker.tags
  tail_consumers       = var.worker.tail_consumers
}

resource "cloudflare_worker_version" "this" {
  count                = var.create && var.create_version ? 1 : 0
  account_id           = var.account_id
  worker_id            = var.create_worker ? cloudflare_worker.this[0].id : var.name
  annotations          = var.script.annotations
  assets               = var.script.assets
  bindings             = var.script.bindings
  cache_options        = var.script.cache_options
  compatibility_date   = var.script.compatibility_date
  compatibility_flags  = var.script.compatibility_flags
  containers           = var.script.containers
  deploy               = var.script.deploy
  exports              = var.script.exports
  include              = var.script.include
  limits               = var.script.limits
  main_module          = var.script.main_module
  migrations           = var.script.migrations
  modules              = var.script.modules
  package_dependencies = var.script.package_dependencies
  placement            = var.script.placement
  usage_model          = var.script.usage_model

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = !var.create_deployment || !var.script.deploy
      error_message = "Separate deployments and script.deploy = true cannot both own traffic allocation."
    }
  }
}

resource "cloudflare_workers_deployment" "this" {
  count       = var.create && var.create_deployment ? 1 : 0
  account_id  = var.account_id
  script_name = local.name
  annotations = var.deployment.annotations
  force       = var.deployment.force
  strategy    = var.deployment.strategy
  versions = [for version in var.deployment.versions : {
    version_id = version.version_id == "current" ? one(cloudflare_worker_version.this[*].id) : version.version_id
    percentage = version.percentage
  }]
  lifecycle {
    precondition {
      condition     = var.create_version || alltrue([for version in var.deployment.versions : version.version_id != "current"])
      error_message = "The current version reference requires create_version = true."
    }
  }
}

resource "cloudflare_workers_route" "this" {
  for_each   = var.create ? var.routes : {}
  zone_id    = each.value.zone_id
  pattern    = each.value.pattern
  script     = each.value.bypass ? null : local.name
  depends_on = [cloudflare_worker_version.this, cloudflare_workers_deployment.this]
}

resource "cloudflare_workers_custom_domain" "this" {
  for_each    = var.create ? var.domains : {}
  account_id  = var.account_id
  service     = local.name
  environment = each.value.environment
  hostname    = each.value.hostname
  zone_id     = each.value.zone_id
  zone_name   = each.value.zone_name
  depends_on  = [cloudflare_worker_version.this, cloudflare_workers_deployment.this]
}

resource "cloudflare_workers_cron_trigger" "this" {
  count       = var.create && var.create_schedules ? 1 : 0
  account_id  = var.account_id
  script_name = local.name
  schedules   = [for cron in distinct([for expression in var.schedules : trimspace(expression)]) : { cron = cron }]
  depends_on  = [cloudflare_worker_version.this, cloudflare_workers_deployment.this]
}
