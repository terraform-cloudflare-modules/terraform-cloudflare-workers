variable "account_id" {
  description = "Cloudflare account containing the example resources."
  type        = string
}

variable "external_namespace_id" {
  description = "Existing namespace in account_id for the external-entry example."
  type        = string
}
