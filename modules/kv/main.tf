resource "cloudflare_workers_kv_namespace" "this" {
  for_each     = var.create ? var.namespaces : {}
  account_id   = each.value.account_id != null ? each.value.account_id : var.account_id
  title        = each.value.title != null ? each.value.title : each.key
  jurisdiction = each.value.jurisdiction
  mode         = each.value.mode
  lifecycle {
    precondition {
      condition     = each.value.account_id != null || var.account_id != null
      error_message = "Each namespace requires an account_id override or module default."
    }
  }
}

resource "cloudflare_workers_kv" "this" {
  for_each       = var.create ? nonsensitive(toset(keys(var.entries))) : toset([])
  account_id     = var.entries[each.key].account_id != null ? var.entries[each.key].account_id : var.account_id
  namespace_id   = try(cloudflare_workers_kv_namespace.this[var.entries[each.key].namespace_id].id, var.entries[each.key].namespace_id)
  key_name       = var.entries[each.key].key_name != null ? var.entries[each.key].key_name : each.key
  value          = var.entries[each.key].value
  expiration     = var.entries[each.key].expiration
  expiration_ttl = var.entries[each.key].expiration_ttl
  metadata       = var.entries[each.key].metadata
  lifecycle {
    precondition {
      condition     = var.entries[each.key].account_id != null || var.account_id != null
      error_message = "Each KV entry requires an account_id override or module default."
    }
  }
}
