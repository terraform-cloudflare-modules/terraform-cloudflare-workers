module "kv" {
  source     = "../../../modules/kv"
  create     = true
  account_id = var.account_id
  namespaces = {
    config = {
      account_id   = var.account_id
      title        = "Shared configuration"
      jurisdiction = "eu"
      mode         = null # Classic KV; use instant when eligible and creating a new namespace.
    }
  }
  entries = {
    features = {
      account_id     = var.account_id
      namespace_id   = "config"
      key_name       = "feature-flags"
      value          = jsonencode({ enabled = true })
      metadata       = jsonencode({ owner = "platform" })
      expiration     = null
      expiration_ttl = 3600
    }
    external = {
      namespace_id   = var.external_namespace_id
      value          = "temporary configuration"
      expiration     = 2000000000
      expiration_ttl = null
    }
  }
}
