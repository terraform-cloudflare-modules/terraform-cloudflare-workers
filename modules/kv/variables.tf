variable "create" {
  description = "Manage configured namespaces and entries. False plans removal."
  type        = bool
  default     = true
  nullable    = false
}

variable "account_id" {
  description = "Default account for namespaces and entries; individual entries can override it."
  type        = string
  default     = null
}

variable "namespaces" {
  description = "Namespaces keyed by stable names. title defaults to the key. Jurisdiction and mode are creation-time choices."
  type = map(object({
    account_id   = optional(string)
    jurisdiction = optional(string)
    mode         = optional(string)
    title        = optional(string)
  }))
  default  = {}
  nullable = false
}

variable "entries" {
  description = "Small configuration entries keyed by non-secret stable identifiers. namespace_id accepts a managed namespace key or existing ID; key_name defaults to the map key. Values are stored in state."
  type = map(object({
    account_id     = optional(string)
    expiration     = optional(number)
    expiration_ttl = optional(number)
    key_name       = optional(string)
    metadata       = optional(string)
    namespace_id   = string
    value          = string
  }))
  default   = {}
  nullable  = false
  sensitive = true
}
