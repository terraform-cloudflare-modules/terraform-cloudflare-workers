# Cloudflare Workers Terraform module

Manage a Worker together with its code version, deployment, routes, custom domains,
and cron schedules. A separate [KV submodule](modules/kv) owns shared namespaces and
configuration entries. Each root call manages one Worker; use multiple calls for
independently deployed services and pass their names through service bindings.

This is a local, unpublished implementation. The example below assumes this
repository is checked out as `terraform-cloudflare-workers` beside the calling root.
A GitHub repository and Registry publication have not been configured.

## Usage

```hcl
variable "account_id" {
  description = "Cloudflare account for the Worker."
  type        = string
}

module "worker" {
  source = "./terraform-cloudflare-workers"

  account_id        = var.account_id
  name              = "status-endpoint"
  create_version    = true
  create_deployment = true
  worker = {
    subdomain = { enabled = true, previews_enabled = false }
  }
  script = {
    compatibility_date = "2026-10-01"
    main_module        = "index.js"
    modules = [{
      name           = "index.js"
      content_type   = "application/javascript+module"
      content_base64 = base64encode("export default { fetch() { return new Response('ok'); } };")
    }]
  }
}
```

The Worker is created, code is uploaded, and a separate deployment directs all
traffic to that version. Enabling its workers.dev URL requires the account's
workers.dev subdomain to be registered already.

## Examples

- [Basic](examples/basic): deploy a Worker from a local JavaScript file.
- [Full](examples/full): every input and nested field, composition with KV, bindings,
  static assets, preview settings, and documented alternatives for migrations and rollout.
- [KV](examples/modules/kv): namespaces, entries, account overrides, and expiration options.

## Configuration

### Ownership and deployment

`create_worker` defaults to true. Set it to false to attach resources to an existing
Worker identified by `name`; metadata settings in `worker` then cannot be supplied.
No lookup or import happens automatically. All resources use the same `account_id`.
Names, patterns, binding payloads, and file contents pass through unchanged.

`create_version`, `create_deployment`, and `create_schedules` default to false and
control separate ownership. Use `script` for the complete version upload payload.
`script.deploy` defaults to false; setting it to true lets the provider deploy that
upload immediately and cannot be combined with `create_deployment = true`.
A metadata-only call leaves code and deployment ownership elsewhere.

For a separately managed deployment, `deployment.versions` defaults to
`[{ version_id = "current", percentage = 100 }]`. The token `current` resolves to the
version uploaded by this call. Literal IDs support canary rollouts or rollback to
existing versions. Percentages must total 100. Upload is required when referencing
`current`; deployments using only external IDs do not require `create_version`.
Only one owner should write a Worker's traffic allocation, including external CI.

Provider versions are immutable: changes to version settings create a new version.
The module creates a replacement before removing its old version resource, and
routes, domains, and schedules wait for configured version/deployment resources.
`force` settings remain optional: review their provider semantics before using them
to bypass reference or rollback checks. Version deletion and active-version
retention are governed by the provider/API; test rollout and rollback in a test account.

### Code, bindings, and state

Build code before running Terraform. Every `script.modules` entry needs a unique
`name`, a `content_type`, and exactly one of `content_file` or `content_base64`.
Use caller-relative paths such as `${path.module}/worker.js`, or `filebase64` and
`base64encode` for explicit payloads. Package metadata does not install or bundle
packages. `script.main_module` identifies the uploaded entry module.

All provider binding fields are exposed, including the current Durable Object retry
settings. Use bindings to reference separately managed services and data products.
Names must be unique within the upload. Missing optional values remain null; false,
zero, empty collections, and empty nested objects are preserved for provider validation.

`script.assets` supports a local asset directory or a previously uploaded manifest's
JWT. These are alternatives. Asset configuration accepts either a boolean or path
rules for `run_worker_first`. `_headers` and `_redirects` can be uploaded as modules
with content type `text/plain`.

Durable Object `exports` and `migrations` are mutually exclusive. They describe
stateful lifecycle operations; class deletion or transfer requires a coordinated
migration, not just a code rename. Container bindings do not provision container
infrastructure. See [coverage and boundaries](docs/COVERAGE.md).

The entire `script` input and `version` output are sensitive because binding text,
keys, and asset tokens can contain secrets. Terraform state still stores them and
uploaded source. Sensitive marking is display protection, not encryption. Keep
resource keys and names non-secret; do not expose sensitive outputs through an
unmarked caller output.

### Routing and schedules

`routes` and `domains` are maps with stable Terraform keys. Their values may include
unknown zone IDs. A route's `bypass = true` omits its script, creating an exclusion;
other routes attach to this Worker. Patterns retain their exact spelling.
Routes require appropriate existing DNS and proxying, which belong to the DNS module.

Custom domains attach the hostname to this Worker and select their zone through
exactly one of `zone_id` or `zone_name`. Cloudflare manages the corresponding custom
domain DNS/certificate behavior. Do not declare a competing DNS record for that
hostname without checking the custom-domain requirements. Domain environments are
passed through; this module does not create separate legacy service environments.

`create_schedules = true` owns the complete schedule list. An empty `schedules` list
clears it; false leaves it unmanaged. Expressions are trimmed and deduplicated,
and execute in UTC. Code must export a scheduled handler. Allow for Cloudflare's
propagation delay before expecting a changed schedule to run.

### Lifecycle and outputs

`create = false` suppresses every resource and plans destruction of existing ones.
Removing map entries removes those routes or domains. Changing ownership flags is
not a way to relinquish state safely; use the [adoption guide](docs/UPGRADING.md).
Flags and map keys must be known at plan time; account/zone IDs, secrets, and deployment
version IDs may be unknown. No live infrastructure is used by the default tests.

Outputs retain complete upstream resource objects. Singletons return null when
unmanaged, maps return empty maps, and `version_id` is available without exposing
version payloads. Formr currently does not fully trace singleton outputs using
`one(...)`; its unused-result counts do not imply those attributes were removed.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.8 |
| cloudflare | >= 5.28.0, < 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| cloudflare | >= 5.28.0, < 6.0.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_worker.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker) | resource |
| [cloudflare_worker_version.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/worker_version) | resource |
| [cloudflare_workers_cron_trigger.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_cron_trigger) | resource |
| [cloudflare_workers_custom_domain.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_custom_domain) | resource |
| [cloudflare_workers_deployment.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_deployment) | resource |
| [cloudflare_workers_route.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_id | Account containing the Worker and all account-scoped child resources. | `string` | `null` | no |
| create | Manage configured resources. False plans removal; it does not pause management. | `bool` | `true` | no |
| create\_deployment | Own traffic allocation separately from version upload. Do not combine with script.deploy = true. | `bool` | `false` | no |
| create\_schedules | Own the complete cron schedule list, including an explicit empty list. | `bool` | `false` | no |
| create\_version | Upload code and bindings from script. Must be known at plan time. | `bool` | `false` | no |
| create\_worker | Own the Worker metadata. False attaches configured children to the existing Worker named by name. | `bool` | `true` | no |
| deployment | Traffic allocation. The version\_id token current resolves to this call's uploaded version; other IDs pass through. Percentages must total 100. | ```object({ annotations = optional(object({ workers_message = optional(string) })) force = optional(bool) strategy = optional(string, "percentage") versions = optional(list(object({ percentage = number version_id = string })), [{ version_id = "current", percentage = 100 }]) })``` | `{}` | no |
| domains | Custom domains keyed by stable identifiers. Service and account come from this call. Supply zone\_id or zone\_name, not both. | ```map(object({ environment = optional(string) hostname = string zone_id = optional(string) zone_name = optional(string) }))``` | `{}` | no |
| name | Exact Worker name. Shared by routes, domains, schedules, and deployments; no normalization is applied. | `string` | `null` | no |
| routes | Zone routes keyed by stable identifiers. Patterns pass through unchanged. bypass = true creates an exclusion route with no script. Existing DNS and proxying are managed separately. | ```map(object({ zone_id = string pattern = string bypass = optional(bool, false) }))``` | `{}` | no |
| schedules | Complete cron expressions when create\_schedules is enabled. Whitespace is trimmed and duplicate expressions are removed; UTC scheduling and limits follow Cloudflare. | `list(string)` | `[]` | no |
| script | Complete version upload settings. Bindings and assets can contain secrets, so the entire input is sensitive. Optional fields remain null; deploy defaults to false for separate rollout ownership. | ```object({ annotations = optional(object({ workers_message = optional(string) workers_tag = optional(string) })) assets = optional(object({ config = optional(object({ base_path = optional(string) html_handling = optional(string) not_found_handling = optional(string) run_worker_first = optional(any) })) directory = optional(string) jwt = optional(string) })) bindings = optional(list(object({ algorithm = optional(string) allowed_destination_addresses = optional(list(string)) allowed_sender_addresses = optional(list(string)) app_id = optional(string) bucket_name = optional(string) certificate_id = optional(string) class_name = optional(string) database_id = optional(string) dataset = optional(string) destination_address = optional(string) dispatch_namespace = optional(string) entrypoint = optional(string) environment = optional(string) format = optional(string) id = optional(string) identity = optional(string) index_name = optional(string) instance_name = optional(string) json = optional(string) jurisdiction = optional(string) key_base64 = optional(string) key_jwk = optional(string) name = string namespace = optional(string) namespace_id = optional(string) network_id = optional(string) old_name = optional(string) outbound = optional(object({ params = optional(list(object({ name = string }))) worker = optional(object({ entrypoint = optional(string) environment = optional(string) service = optional(string) })) })) part = optional(string) pipeline = optional(string) queue_name = optional(string) retry = optional(object({ max_attempts = optional(number) timeout_ms = optional(number) })) script_name = optional(string) secret_name = optional(string) service = optional(string) service_id = optional(string) simple = optional(object({ limit = number mitigation_timeout = optional(number) period = number })) store_id = optional(string) stream = optional(string) text = optional(string) tunnel_id = optional(string) type = string usages = optional(set(string)) version_id = optional(string) workflow_name = optional(string) }))) cache_options = optional(object({ cross_version_cache = optional(bool) enabled = optional(bool) })) compatibility_date = optional(string) compatibility_flags = optional(set(string)) containers = optional(set(object({ class_name = string }))) deploy = optional(bool, false) exports = optional(map(object({ cache = optional(object({ enabled = bool })) renamed_to = optional(string) state = optional(string) storage = optional(string) transfer_from = optional(string) transferred_to = optional(string) type = string }))) include = optional(string) limits = optional(object({ cpu_ms = optional(number) subrequests = optional(number) })) main_module = optional(string) migrations = optional(object({ deleted_classes = optional(list(string)) new_classes = optional(list(string)) new_sqlite_classes = optional(list(string)) new_tag = optional(string) old_tag = optional(string) renamed_classes = optional(list(object({ from = optional(string) to = optional(string) }))) steps = optional(list(object({ deleted_classes = optional(list(string)) new_classes = optional(list(string)) new_sqlite_classes = optional(list(string)) renamed_classes = optional(list(object({ from = optional(string) to = optional(string) }))) transferred_classes = optional(list(object({ from = optional(string) from_script = optional(string) to = optional(string) }))) }))) transferred_classes = optional(list(object({ from = optional(string) from_script = optional(string) to = optional(string) }))) })) modules = optional(set(object({ content_base64 = optional(string) content_file = optional(string) content_type = string name = string }))) package_dependencies = optional(list(object({ installed_version = string name = string package_json_version = string }))) placement = optional(object({ host = optional(string) hostname = optional(string) mode = optional(string) region = optional(string) target = optional(list(object({ host = optional(string) hostname = optional(string) region = optional(string) }))) })) usage_model = optional(string) })``` | `{}` | no |
| worker | Worker metadata, preview defaults, observability, subdomain flags, tags, and tail consumers. Null fields defer to the provider. | ```object({ force = optional(bool) logpush = optional(bool) observability = optional(object({ enabled = optional(bool) head_sampling_rate = optional(number) issues = optional(object({ enabled = optional(bool) })) logs = optional(object({ destinations = optional(list(string)) enabled = optional(bool) head_sampling_rate = optional(number) invocation_logs = optional(bool) persist = optional(bool) })) traces = optional(object({ destinations = optional(list(string)) enabled = optional(bool) head_sampling_rate = optional(number) persist = optional(bool) propagation_policy = optional(string) })) })) previews_base_config = optional(object({ cache_options = optional(object({ cross_version_cache = optional(bool) enabled = optional(bool) })) env = optional(map(object({ type = string }))) limits = optional(object({ cpu_ms = optional(number) subrequests = optional(number) })) logpush = optional(bool) observability = optional(object({ enabled = optional(bool) head_sampling_rate = optional(number) issues = optional(object({ enabled = optional(bool) })) logs = optional(object({ destinations = optional(list(string)) enabled = optional(bool) head_sampling_rate = optional(number) invocation_logs = optional(bool) persist = optional(bool) })) redact_query_string = optional(bool) traces = optional(object({ destinations = optional(list(string)) enabled = optional(bool) head_sampling_rate = optional(number) persist = optional(bool) propagation_policy = optional(string) })) })) placement = optional(object({ host = optional(string) hostname = optional(string) mode = optional(string) region = optional(string) target = optional(list(object({ host = optional(string) hostname = optional(string) region = optional(string) }))) })) tail_consumers = optional(set(object({ name = string }))) })) subdomain = optional(object({ enabled = optional(bool) previews_enabled = optional(bool) })) tags = optional(set(string)) tail_consumers = optional(set(object({ name = string }))) })``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| deployment | Complete managed deployment, or null when unmanaged. |
| domains | Complete custom domain resources keyed by input keys. |
| name | Worker name, including in existing-Worker mode. Null when disabled. |
| routes | Complete route resources keyed by input keys. |
| schedules | Complete cron trigger resource, or null when unmanaged. |
| version | Complete uploaded version. Sensitive because bindings, code, and asset tokens can contain secrets. |
| version\_id | Uploaded version ID, or null when version upload is disabled. |
| worker | Complete managed Worker, including computed references and URLs. Null in existing-Worker mode. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for local checks and contribution guidelines,
[UPGRADING.md](docs/UPGRADING.md) for adoption and acceptance checks, and the generated
[schema report](docs/SCHEMA.md) for provider coverage.

## Authors

Maintained by [Terraform Cloudflare Modules](https://github.com/terraform-cloudflare-modules).
See [AUTHORS](.github/AUTHORS) and [CODEOWNERS](.github/CODEOWNERS).

## License

MIT. See [LICENSE](LICENSE).
