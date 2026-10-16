variable "create" {
  description = "Manage configured resources. False plans removal; it does not pause management."
  type        = bool
  default     = true
  nullable    = false
}

variable "create_worker" {
  description = "Own the Worker metadata. False attaches configured children to the existing Worker named by name."
  type        = bool
  default     = true
  nullable    = false
}

variable "create_version" {
  description = "Upload code and bindings from script. Must be known at plan time."
  type        = bool
  default     = false
  nullable    = false
}

variable "create_deployment" {
  description = "Own traffic allocation separately from version upload. Do not combine with script.deploy = true."
  type        = bool
  default     = false
  nullable    = false
}

variable "create_schedules" {
  description = "Own the complete cron schedule list, including an explicit empty list."
  type        = bool
  default     = false
  nullable    = false
}

variable "account_id" {
  description = "Account containing the Worker and all account-scoped child resources."
  type        = string
  default     = null
  validation {
    condition     = var.account_id == null ? true : length(trimspace(var.account_id)) > 0
    error_message = "account_id must be null or nonempty."
  }
}

variable "name" {
  description = "Exact Worker name. Shared by routes, domains, schedules, and deployments; no normalization is applied."
  type        = string
  default     = null
  validation {
    condition     = var.name == null ? true : length(trimspace(var.name)) > 0
    error_message = "name must be null or nonempty."
  }
}

variable "worker" {
  description = "Worker metadata, preview defaults, observability, subdomain flags, tags, and tail consumers. Null fields defer to the provider."
  type = object({
    force   = optional(bool)
    logpush = optional(bool)
    observability = optional(object({
      enabled            = optional(bool)
      head_sampling_rate = optional(number)
      issues = optional(object({
        enabled = optional(bool)
      }))
      logs = optional(object({
        destinations       = optional(list(string))
        enabled            = optional(bool)
        head_sampling_rate = optional(number)
        invocation_logs    = optional(bool)
        persist            = optional(bool)
      }))
      traces = optional(object({
        destinations       = optional(list(string))
        enabled            = optional(bool)
        head_sampling_rate = optional(number)
        persist            = optional(bool)
        propagation_policy = optional(string)
      }))
    }))
    previews_base_config = optional(object({
      cache_options = optional(object({
        cross_version_cache = optional(bool)
        enabled             = optional(bool)
      }))
      env = optional(map(object({
        type = string
      })))
      limits = optional(object({
        cpu_ms      = optional(number)
        subrequests = optional(number)
      }))
      logpush = optional(bool)
      observability = optional(object({
        enabled            = optional(bool)
        head_sampling_rate = optional(number)
        issues = optional(object({
          enabled = optional(bool)
        }))
        logs = optional(object({
          destinations       = optional(list(string))
          enabled            = optional(bool)
          head_sampling_rate = optional(number)
          invocation_logs    = optional(bool)
          persist            = optional(bool)
        }))
        redact_query_string = optional(bool)
        traces = optional(object({
          destinations       = optional(list(string))
          enabled            = optional(bool)
          head_sampling_rate = optional(number)
          persist            = optional(bool)
          propagation_policy = optional(string)
        }))
      }))
      placement = optional(object({
        host     = optional(string)
        hostname = optional(string)
        mode     = optional(string)
        region   = optional(string)
        target = optional(list(object({
          host     = optional(string)
          hostname = optional(string)
          region   = optional(string)
        })))
      }))
      tail_consumers = optional(set(object({
        name = string
      })))
    }))
    subdomain = optional(object({
      enabled          = optional(bool)
      previews_enabled = optional(bool)
    }))
    tags = optional(set(string))
    tail_consumers = optional(set(object({
      name = string
    })))
  })
  default  = {}
  nullable = false
}

variable "script" {
  description = "Complete version upload settings. Bindings and assets can contain secrets, so the entire input is sensitive. Optional fields remain null; deploy defaults to false for separate rollout ownership."
  type = object({
    annotations = optional(object({
      workers_message = optional(string)
      workers_tag     = optional(string)
    }))
    assets = optional(object({
      config = optional(object({
        base_path          = optional(string)
        html_handling      = optional(string)
        not_found_handling = optional(string)
        run_worker_first   = optional(any)
      }))
      directory = optional(string)
      jwt       = optional(string)
    }))
    bindings = optional(list(object({
      algorithm                     = optional(string)
      allowed_destination_addresses = optional(list(string))
      allowed_sender_addresses      = optional(list(string))
      app_id                        = optional(string)
      bucket_name                   = optional(string)
      certificate_id                = optional(string)
      class_name                    = optional(string)
      database_id                   = optional(string)
      dataset                       = optional(string)
      destination_address           = optional(string)
      dispatch_namespace            = optional(string)
      entrypoint                    = optional(string)
      environment                   = optional(string)
      format                        = optional(string)
      id                            = optional(string)
      identity                      = optional(string)
      index_name                    = optional(string)
      instance_name                 = optional(string)
      json                          = optional(string)
      jurisdiction                  = optional(string)
      key_base64                    = optional(string)
      key_jwk                       = optional(string)
      name                          = string
      namespace                     = optional(string)
      namespace_id                  = optional(string)
      network_id                    = optional(string)
      old_name                      = optional(string)
      outbound = optional(object({
        params = optional(list(object({
          name = string
        })))
        worker = optional(object({
          entrypoint  = optional(string)
          environment = optional(string)
          service     = optional(string)
        }))
      }))
      part       = optional(string)
      pipeline   = optional(string)
      queue_name = optional(string)
      retry = optional(object({
        max_attempts = optional(number)
        timeout_ms   = optional(number)
      }))
      script_name = optional(string)
      secret_name = optional(string)
      service     = optional(string)
      service_id  = optional(string)
      simple = optional(object({
        limit              = number
        mitigation_timeout = optional(number)
        period             = number
      }))
      store_id      = optional(string)
      stream        = optional(string)
      text          = optional(string)
      tunnel_id     = optional(string)
      type          = string
      usages        = optional(set(string))
      version_id    = optional(string)
      workflow_name = optional(string)
    })))
    cache_options = optional(object({
      cross_version_cache = optional(bool)
      enabled             = optional(bool)
    }))
    compatibility_date  = optional(string)
    compatibility_flags = optional(set(string))
    containers = optional(set(object({
      class_name = string
    })))
    deploy = optional(bool, false)
    exports = optional(map(object({
      cache = optional(object({
        enabled = bool
      }))
      renamed_to     = optional(string)
      state          = optional(string)
      storage        = optional(string)
      transfer_from  = optional(string)
      transferred_to = optional(string)
      type           = string
    })))
    include = optional(string)
    limits = optional(object({
      cpu_ms      = optional(number)
      subrequests = optional(number)
    }))
    main_module = optional(string)
    migrations = optional(object({
      deleted_classes    = optional(list(string))
      new_classes        = optional(list(string))
      new_sqlite_classes = optional(list(string))
      new_tag            = optional(string)
      old_tag            = optional(string)
      renamed_classes = optional(list(object({
        from = optional(string)
        to   = optional(string)
      })))
      steps = optional(list(object({
        deleted_classes    = optional(list(string))
        new_classes        = optional(list(string))
        new_sqlite_classes = optional(list(string))
        renamed_classes = optional(list(object({
          from = optional(string)
          to   = optional(string)
        })))
        transferred_classes = optional(list(object({
          from        = optional(string)
          from_script = optional(string)
          to          = optional(string)
        })))
      })))
      transferred_classes = optional(list(object({
        from        = optional(string)
        from_script = optional(string)
        to          = optional(string)
      })))
    }))
    modules = optional(set(object({
      content_base64 = optional(string)
      content_file   = optional(string)
      content_type   = string
      name           = string
    })))
    package_dependencies = optional(list(object({
      installed_version    = string
      name                 = string
      package_json_version = string
    })))
    placement = optional(object({
      host     = optional(string)
      hostname = optional(string)
      mode     = optional(string)
      region   = optional(string)
      target = optional(list(object({
        host     = optional(string)
        hostname = optional(string)
        region   = optional(string)
      })))
    }))
    usage_model = optional(string)
  })
  default   = {}
  nullable  = false
  sensitive = true
  validation {
    condition     = var.script.exports == null || var.script.migrations == null
    error_message = "script.exports and script.migrations are mutually exclusive."
  }
  validation {
    condition     = try(var.script.assets.directory, null) == null || try(var.script.assets.jwt, null) == null
    error_message = "Use an asset directory or an upload JWT, not both."
  }
  validation {
    condition = var.script.modules == null ? true : alltrue([
      for item in var.script.modules : (item.content_file != null) != (item.content_base64 != null)
    ])
    error_message = "Each script module needs exactly one of content_file or content_base64."
  }
  validation {
    condition     = var.script.modules == null ? true : length(distinct([for item in var.script.modules : item.name])) == length(var.script.modules)
    error_message = "Script module names must be unique."
  }
  validation {
    condition     = var.script.bindings == null ? true : length(distinct([for binding in var.script.bindings : binding.name])) == length(var.script.bindings)
    error_message = "Binding names must be unique."
  }
}

variable "deployment" {
  description = "Traffic allocation. The version_id token current resolves to this call's uploaded version; other IDs pass through. Percentages must total 100."
  type = object({
    annotations = optional(object({
      workers_message = optional(string)
    }))
    force    = optional(bool)
    strategy = optional(string, "percentage")
    versions = optional(list(object({
      percentage = number
      version_id = string
    })), [{ version_id = "current", percentage = 100 }])
  })
  default  = {}
  nullable = false
  validation {
    condition = try(length(var.deployment.versions) > 0 && sum([for version in var.deployment.versions : version.percentage]) == 100 && alltrue([
      for version in var.deployment.versions : version.percentage >= 0 && version.percentage <= 100 && length(trimspace(version.version_id)) > 0
    ]), false)
    error_message = "Deployment versions require nonempty IDs and percentages between 0 and 100 totaling 100."
  }
  validation {
    condition     = length(distinct([for version in var.deployment.versions : version.version_id])) == length(var.deployment.versions)
    error_message = "Each version may appear only once in a deployment."
  }
}

variable "routes" {
  description = "Zone routes keyed by stable identifiers. Patterns pass through unchanged. bypass = true creates an exclusion route with no script. Existing DNS and proxying are managed separately."
  type = map(object({
    zone_id = string
    pattern = string
    bypass  = optional(bool, false)
  }))
  default  = {}
  nullable = false
}

variable "domains" {
  description = "Custom domains keyed by stable identifiers. Service and account come from this call. Supply zone_id or zone_name, not both."
  type = map(object({
    environment = optional(string)
    hostname    = string
    zone_id     = optional(string)
    zone_name   = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for domain in var.domains : (domain.zone_id != null) != (domain.zone_name != null)])
    error_message = "Each custom domain must select exactly one of zone_id or zone_name."
  }
}

variable "schedules" {
  description = "Complete cron expressions when create_schedules is enabled. Whitespace is trimmed and duplicate expressions are removed; UTC scheduling and limits follow Cloudflare."
  type        = list(string)
  default     = []
  nullable    = false
  validation {
    condition     = alltrue([for cron in var.schedules : try(length(trimspace(cron)) > 0, false)])
    error_message = "Schedule expressions must be nonempty strings."
  }
}
