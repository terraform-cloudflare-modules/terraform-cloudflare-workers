module "worker" {
  source            = "../.."
  account_id        = var.account_id
  name              = "file-worker-example"
  create_version    = true
  create_deployment = true
  worker            = { subdomain = { enabled = true, previews_enabled = false } }
  script = {
    compatibility_date = "2026-10-01"
    main_module        = "worker.js"
    modules            = [{ name = "worker.js", content_type = "application/javascript+module", content_file = "${path.module}/worker.js" }]
  }
}
