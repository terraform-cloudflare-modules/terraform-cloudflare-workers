module "kv" {
  source     = "../../modules/kv"
  account_id = var.account_id
  namespaces = { config = { title = "Worker example configuration" } }
  entries    = { features = { namespace_id = "config", value = jsonencode({ enabled = true }) } }
}

module "worker" {
  source            = "../.."
  create            = true
  create_worker     = true
  create_version    = true
  create_deployment = true
  create_schedules  = true
  account_id        = var.account_id
  name              = "complete-worker-example"

  worker = {
    force          = false
    logpush        = false
    tags           = ["managed-by:terraform"]
    subdomain      = { enabled = false, previews_enabled = true }
    tail_consumers = var.tail_worker_name == null ? [] : [{ name = var.tail_worker_name }]
    observability = {
      enabled            = true
      head_sampling_rate = 1
      issues             = { enabled = false }
      logs = {
        enabled            = true
        destinations       = []
        head_sampling_rate = 1
        invocation_logs    = true
        persist            = true
      }
      traces = {
        enabled            = false
        destinations       = []
        head_sampling_rate = 0.1
        persist            = false
        propagation_policy = null # "authenticated" or "accept" requires trace propagation access.
      }
    }
    previews_base_config = {
      cache_options = { enabled = false, cross_version_cache = false }
      env           = { CONFIG = { type = "kv_namespace" } }
      limits        = { cpu_ms = 50, subrequests = 1000 }
      logpush       = false
      observability = {
        enabled            = true
        head_sampling_rate = 1
        issues             = { enabled = false }
        logs = {
          enabled            = true
          destinations       = []
          head_sampling_rate = 1
          invocation_logs    = true
          persist            = true
        }
        redact_query_string = true
        traces = {
          enabled            = false
          destinations       = []
          head_sampling_rate = 0.1
          persist            = false
          propagation_policy = null
        }
      }
      placement = {
        mode     = "smart"
        host     = null # Alternative targeted placement: "database.example.com:5432".
        hostname = null # Alternative HTTP target: "api.example.com".
        region   = null # Alternative regional target: "aws:eu-west-1".
        target   = null # Alternative target list: see README; do not mix targeting modes.
      }
      tail_consumers = var.tail_worker_name == null ? [] : [{ name = var.tail_worker_name }]
    }
  }

  script = {
    deploy              = false # true is available when create_deployment = false.
    annotations         = { workers_message = "Complete module example", workers_tag = "example-v1" }
    compatibility_date  = "2026-10-01"
    compatibility_flags = ["nodejs_compat"]
    main_module         = "worker.js"
    include             = "modules"
    modules = [
      {
        name           = "worker.js"
        content_type   = "application/javascript+module"
        content_file   = "${path.module}/worker.js"
        content_base64 = null # Mutually exclusive with content_file.
      },
      {
        name           = "_headers"
        content_type   = "text/plain"
        content_file   = null
        content_base64 = base64encode("/*\n  X-Content-Type-Options: nosniff\n")
      }
    ]
    assets = {
      directory = "${path.module}/assets"
      jwt       = null # Alternative: upload-manifest token, with directory = null.
      config = {
        base_path          = "/"
        html_handling      = "auto-trailing-slash"
        not_found_handling = "404-page"
        run_worker_first   = ["/api/*", "!/api/public/*"] # Boolean true/false is also supported.
      }
    }
    bindings = [
      { name = "ASSETS", type = "assets" },
      { name = "CONFIG", type = "kv_namespace", namespace_id = module.kv.namespace_ids.config },
      { name = "OPTIONS", type = "json", json = jsonencode({ enabled = true, retries = 0 }) },
      {
        name               = "COUNTER"
        type               = "durable_object_namespace"
        class_name         = "Counter"
        script_name        = null # Null binds the class in this Worker; a name binds an external class.
        environment        = null
        dispatch_namespace = null # Needed only for a class in an external dispatch script.
        retry              = { max_attempts = 0, timeout_ms = 10000 }
      }
    ]
    cache_options = { enabled = false, cross_version_cache = false }
    containers    = [] # Alternative: [{ class_name = "ContainerClass" }] after container provisioning.
    exports = {
      default = { type = "worker", state = "created", cache = { enabled = false } }
      Counter = {
        type           = "durable-object"
        storage        = "sqlite"
        state          = "created"
        renamed_to     = null
        transfer_from  = null
        transferred_to = null
        cache          = null # Cache overrides apply to Worker entrypoints, not Durable Objects.
      }
    }
    migrations           = null # Alternative to exports: see README for all migration fields.
    limits               = { cpu_ms = 50, subrequests = 1000 }
    package_dependencies = [] # Metadata only; see README for an entry representing a real build.
    placement = {
      mode     = "smart"
      host     = null
      hostname = null
      region   = null
      target   = null
    }
    usage_model = null # Deprecated upstream; "standard" is still available for compatibility.
  }

  deployment = {
    strategy    = "percentage"
    versions    = [{ version_id = "current", percentage = 100 }]
    force       = false
    annotations = { workers_message = "Activate uploaded version" }
  }
  routes = {
    api      = { zone_id = var.zone_id, pattern = "${var.zone_name}/api/*", bypass = false }
    excluded = { zone_id = var.zone_id, pattern = "${var.zone_name}/api/public/*", bypass = true }
  }
  domains = {
    app = {
      hostname    = "worker.${var.zone_name}"
      environment = "production"
      zone_id     = var.zone_id
      zone_name   = null # Alternative: use var.zone_name and set zone_id = null.
    }
  }
  schedules = ["0 * * * *"]
}
