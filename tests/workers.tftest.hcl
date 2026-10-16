mock_provider "cloudflare" {
  mock_resource "cloudflare_worker" {
    defaults = { id = "11111111111111111111111111111111" }
  }
  mock_resource "cloudflare_worker_version" {
    defaults = { id = "22222222-2222-4222-8222-222222222222" }
  }
}

variables {
  account_id = "0123456789abcdef0123456789abcdef"
  name       = "test-worker"
}

run "compose_worker_version_rollout_and_triggers" {
  command = apply
  variables {
    create_version    = true
    create_deployment = true
    create_schedules  = true
    worker            = { subdomain = { enabled = false, previews_enabled = false }, tags = ["managed"] }
    script = {
      main_module        = "index.js"
      compatibility_date = "2026-10-01"
      modules            = [{ name = "index.js", content_type = "application/javascript+module", content_base64 = base64encode("export default { fetch() { return new Response('ok'); } };") }]
      bindings           = [{ name = "CONFIG", type = "json", json = jsonencode({ enabled = false, retries = 0 }) }]
      limits             = { cpu_ms = 50 }
    }
    schedules = [" */5 * * * * ", "*/5 * * * *", "0 0 * * *"]
    routes    = { api = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", pattern = "example.com/api/*" }, bypass = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", pattern = "example.com/api/public/*", bypass = true } }
    domains   = { app = { zone_name = "example.com", hostname = "worker.example.com", environment = "production" } }

  }
  assert {
    condition     = output.name == "test-worker" && output.worker.subdomain.enabled == false && output.worker.subdomain.previews_enabled == false
    error_message = "Explicit subdomain false flags must be preserved."
  }
  assert {
    condition     = output.version.worker_id == output.worker.id && output.deployment.versions[0].version_id == output.version_id && output.deployment.versions[0].percentage == 100
    error_message = "The deployment must reference the uploaded version of this Worker."
  }
  assert {
    condition     = output.routes.api.script == output.name && output.routes.bypass.script == null && output.domains.app.service == output.name
    error_message = "Routes and domains must attach to the Worker; bypass must remain scriptless."
  }
  assert {
    condition     = length(output.schedules.schedules) == 2 && output.schedules.schedules[0].cron == "*/5 * * * *"
    error_message = "Cron expressions must be trimmed and deduplicated."
  }
  assert {
    condition     = jsondecode(output.version.bindings[0].json).retries == 0 && !jsondecode(output.version.bindings[0].json).enabled
    error_message = "Binding payloads must preserve zero and false."
  }
}

run "metadata_only_default" {
  command = plan
  assert {
    condition     = output.version == null && output.deployment == null && output.schedules == null && length(output.routes) == 0
    error_message = "Optional resources must remain unmanaged by default."
  }
}

run "existing_worker_gradual_rollout" {
  command = plan
  variables {
    create_worker     = false
    create_deployment = true
    deployment = {
      versions = [
        { version_id = "22222222-2222-4222-8222-222222222222", percentage = 90 },
        { version_id = "33333333-3333-4333-8333-333333333333", percentage = 10 }
      ]
      annotations = { workers_message = "Canary rollout" }
      force       = false
    }

  }
  assert {
    condition     = output.worker == null && output.deployment.script_name == "test-worker" && output.deployment.versions[1].percentage == 10 && output.deployment.force == false
    error_message = "Existing Workers must support external-version deployments without metadata ownership."
  }
}

run "version_can_deploy_without_separate_rollout" {
  command = plan
  variables {
    create_version    = true
    create_deployment = false
    create_schedules  = false
    worker            = { subdomain = { enabled = false, previews_enabled = false }, tags = ["managed"] }
    script = {
      deploy             = true
      main_module        = "index.js"
      compatibility_date = "2026-10-01"
      modules            = [{ name = "index.js", content_type = "application/javascript+module", content_base64 = base64encode("export default { fetch() { return new Response('ok'); } };") }]
      bindings           = [{ name = "CONFIG", type = "json", json = jsonencode({ enabled = false, retries = 0 }) }]
      limits             = { cpu_ms = 50 }
    }

  }
  assert {
    condition     = output.version.deploy && output.deployment == null
    error_message = "Provider auto-deployment must remain available with no competing deployment owner."
  }
}

run "empty_schedule_clears_owned_list" {
  command = plan
  variables {
    create_schedules = true
    schedules        = []
  }
  assert {
    condition     = length(output.schedules.schedules) == 0
    error_message = "An explicitly managed empty schedule list must not disable ownership."
  }
}

run "disabled_suppresses_all_resources" {
  command = plan
  variables {
    create_version    = true
    create_deployment = true
    create_schedules  = true
    worker            = { subdomain = { enabled = false, previews_enabled = false }, tags = ["managed"] }
    script = {
      main_module        = "index.js"
      compatibility_date = "2026-10-01"
      modules            = [{ name = "index.js", content_type = "application/javascript+module", content_base64 = base64encode("export default { fetch() { return new Response('ok'); } };") }]
      bindings           = [{ name = "CONFIG", type = "json", json = jsonencode({ enabled = false, retries = 0 }) }]
      limits             = { cpu_ms = 50 }
    }
    schedules = [" */5 * * * * ", "*/5 * * * *", "0 0 * * *"]
    routes    = { api = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", pattern = "example.com/api/*" }, bypass = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", pattern = "example.com/api/public/*", bypass = true } }
    domains   = { app = { zone_name = "example.com", hostname = "worker.example.com", environment = "production" } }

    create = false
  }
  assert {
    condition     = output.worker == null && output.version == null && output.deployment == null && output.schedules == null && length(output.routes) == 0 && length(output.domains) == 0
    error_message = "Global disable must suppress every managed resource."
  }
}

run "reject_competing_rollout_owners" {
  command = plan
  variables {
    create_version    = true
    create_deployment = true
    create_schedules  = true
    worker            = { subdomain = { enabled = false, previews_enabled = false }, tags = ["managed"] }
    script = {
      deploy             = true
      main_module        = "index.js"
      compatibility_date = "2026-10-01"
      modules            = [{ name = "index.js", content_type = "application/javascript+module", content_base64 = base64encode("export default { fetch() { return new Response('ok'); } };") }]
      bindings           = [{ name = "CONFIG", type = "json", json = jsonencode({ enabled = false, retries = 0 }) }]
      limits             = { cpu_ms = 50 }
    }
    schedules = [" */5 * * * * ", "*/5 * * * *", "0 0 * * *"]
    routes    = { api = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", pattern = "example.com/api/*" }, bypass = { zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", pattern = "example.com/api/public/*", bypass = true } }
    domains   = { app = { zone_name = "example.com", hostname = "worker.example.com", environment = "production" } }

  }
  expect_failures = [cloudflare_worker_version.this]
}

run "reject_current_without_upload" {
  command = plan
  variables {
    create_deployment = true
  }
  expect_failures = [cloudflare_workers_deployment.this]
}

run "reject_incomplete_traffic" {
  command = plan
  variables {
    deployment = { versions = [{ version_id = "external", percentage = 90 }] }
  }
  expect_failures = [var.deployment]
}

run "reject_duplicate_binding_names" {
  command = plan
  variables {
    script = { bindings = [{ name = "CONFIG", type = "plain_text", text = "one" }, { name = "CONFIG", type = "plain_text", text = "two" }] }
  }
  expect_failures = [var.script]
}

run "reject_both_code_sources" {
  command = plan
  variables {
    script = { modules = [{ name = "index.js", content_type = "application/javascript+module", content_file = "index.js", content_base64 = "ZXhwb3J0" }] }
  }
  expect_failures = [var.script]
}

run "reject_exports_and_migrations" {
  command = plan
  variables {
    script = { exports = { Counter = { type = "durable-object", storage = "sqlite" } }, migrations = { new_tag = "v1", new_sqlite_classes = ["Counter"] } }
  }
  expect_failures = [var.script]
}

run "reject_ambiguous_domain_zone" {
  command = plan
  variables {
    domains = { app = { hostname = "app.example.com", zone_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", zone_name = "example.com" } }
  }
  expect_failures = [var.domains]
}

run "reject_unowned_worker_settings" {
  command = plan
  variables {
    create_worker = false
    worker        = { logpush = false }
  }
  expect_failures = [output.name]
}

run "reject_unowned_schedules" {
  command = plan
  variables {
    schedules = ["0 * * * *"]
  }
  expect_failures = [output.name]
}

run "asset_routing_boolean" {
  command = plan
  variables {
    create_version = true
    script = {
      main_module        = "worker.js"
      compatibility_date = "2026-10-01"
      modules            = [{ name = "worker.js", content_type = "application/javascript+module", content_file = "./examples/basic/worker.js" }]
      assets = {
        directory = "./examples/full/assets"
        config    = { run_worker_first = true }
      }
    }
  }
  assert {
    condition     = output.version.assets.config.run_worker_first == true
    error_message = "Asset routing must retain its boolean-or-rules type."
  }
}

run "asset_routing_rules" {
  command = plan
  variables {
    create_version = true
    script = {
      main_module        = "worker.js"
      compatibility_date = "2026-10-01"
      modules            = [{ name = "worker.js", content_type = "application/javascript+module", content_file = "./examples/basic/worker.js" }]
      assets = {
        directory = "./examples/full/assets"
        config    = { run_worker_first = ["/api/*", "!/api/public/*"] }
      }
    }
  }
  assert {
    condition     = join(",", output.version.assets.config.run_worker_first) == "/api/*,!/api/public/*"
    error_message = "Asset routing must retain its boolean-or-rules type."
  }
}

run "reject_missing_account_for_existing_worker" {
  command = plan
  variables {
    create_worker = false
    account_id    = null
  }
  expect_failures = [output.name]
}

run "reject_empty_deployment" {
  command = plan
  variables {
    deployment = { versions = [] }
  }
  expect_failures = [var.deployment]
}
