mock_provider "cloudflare" {
  mock_resource "cloudflare_workers_kv_namespace" {
    defaults = { id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" }
  }
}
variables { account_id = "0123456789abcdef0123456789abcdef" }

run "namespace_references_sensitive_values_and_overrides" {
  command = apply
  variables {
    namespaces = { cache = { title = "Shared cache", jurisdiction = "eu" } }
    entries    = { config = { namespace_id = "cache", key_name = "configuration", value = "exact value", metadata = jsonencode({ revision = 1 }), expiration_ttl = 300 } }

  }
  assert {
    condition     = output.entries.config.namespace_id == output.namespace_ids.cache && output.entries.config.key_name == "configuration" && output.entries.config.value == "exact value"
    error_message = "Managed namespace references and explicit entry names must resolve without exposing values in addresses."
  }
  assert {
    condition     = output.namespaces.cache.title == "Shared cache" && output.namespaces.cache.jurisdiction == "eu" && output.entries.config.expiration_ttl == 300
    error_message = "Namespace options and expiration must be forwarded."
  }
}

run "external_namespace_and_default_names" {
  command = plan
  variables {
    entries = { config = { namespace_id = "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb", value = "payload", expiration = 2000000000 } }
  }
  assert {
    condition     = output.entries.config.namespace_id == "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" && output.entries.config.key_name == "config" && length(output.namespaces) == 0
    error_message = "External namespaces must not be adopted."
  }
}

run "account_overrides_and_instant_namespace" {
  command = plan
  variables {
    account_id = null
    namespaces = { cache = { account_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", mode = "instant" } }
    entries    = { config = { account_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", namespace_id = "cache", value = "payload" } }
  }
  assert {
    condition     = output.namespaces.cache.title == "cache" && output.namespaces.cache.mode == "instant" && output.entries.config.account_id == "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
    error_message = "Account overrides and namespace key defaults must work without a module account."
  }
}

run "disabled" {
  command = plan
  variables {
    create     = false
    account_id = null
    namespaces = { cache = {} }
    entries    = { config = { namespace_id = "cache", value = "payload" } }
  }
  assert {
    condition     = length(output.namespaces) == 0 && length(output.entries) == 0
    error_message = "Disabled KV must create nothing."
  }
}

run "reject_missing_account" {
  command = plan
  variables {
    account_id = null
    namespaces = { cache = {} }
  }
  expect_failures = [cloudflare_workers_kv_namespace.this]
}
