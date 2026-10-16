locals {
  name = var.create ? (var.create_worker ? cloudflare_worker.this[0].name : var.name) : null
}
