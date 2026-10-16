variable "account_id" {
  description = "Cloudflare account with Workers and required optional features enabled."
  type        = string
}
variable "zone_id" {
  description = "Existing zone containing the route and custom domain."
  type        = string
}
variable "zone_name" {
  description = "Domain name for the existing zone."
  type        = string
}
variable "tail_worker_name" {
  description = "Existing tail consumer in the same account, or null to omit tail consumption."
  type        = string
  default     = null
}
