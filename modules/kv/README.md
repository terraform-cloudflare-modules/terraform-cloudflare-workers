# Cloudflare Workers KV Terraform module

Manage shared KV namespaces and small configuration entries independently of
Worker deployment. Application data and bulk synchronization belong outside Terraform.
This is a local, unpublished submodule.

## Usage

From a calling root beside the `terraform-cloudflare-workers` checkout:

```hcl
variable "account_id" {
  description = "Account containing the shared KV namespace."
  type        = string
}

module "kv" {
  source = "./terraform-cloudflare-workers/modules/kv"

  account_id = var.account_id
  namespaces = { configuration = { title = "Shared configuration" } }
  entries = {
    feature_flags = {
      namespace_id = "configuration"
      key_name     = "features"
      value        = jsonencode({ maintenance = false })
    }
  }
}
```

Pass `module.kv.namespace_ids.configuration` into a Worker's `kv_namespace` binding.

## Examples

See the [full example](../../examples/modules/kv) for all namespace and entry fields,
expiration choices, external namespace references, and account overrides.

## Configuration and lifecycle

Map keys must be stable and known at plan time. Namespace titles and entry key names
default to those keys. `namespace_id` resolves a matching namespace key first, otherwise
it is forwarded as an existing ID. Avoid key/ID collisions. Account IDs default from
the module; per-entry overrides are available and must match the referenced namespace.
Overriding a namespace's account does not change the account default for its entries.

`jurisdiction` and `mode` are creation-time choices. `mode = "instant"` selects KV
Instant; null leaves the provider's classic behavior. Changes can replace namespaces
without migrating their data. The module does not perform data migration.

Use `expiration` for an absolute Unix timestamp or `expiration_ttl` for a lifetime
in seconds. Upstream gives TTL precedence when both are supplied; TTL must be at
least 60. `metadata` accepts a JSON string, conveniently built with `jsonencode`.
Optional nulls defer to the provider. Provider/API restrictions remain authoritative.

Only entry map keys are declassified for Terraform addresses. Never use secret values
as keys. The entire `entries` input/output is sensitive, but values remain in state.
`namespaces` returns complete resources and `namespace_ids` supplies binding references.

Removing entries deletes their keys; removing namespaces deletes their data and can
break every bound Worker. `create = false` plans removal of all owned resources.
Designate one owner for shared namespaces and coordinate state handoffs before removal.

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
| [cloudflare_workers_kv.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv) | resource |
| [cloudflare_workers_kv_namespace.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_kv_namespace) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| account\_id | Default account for namespaces and entries; individual entries can override it. | `string` | `null` | no |
| create | Manage configured namespaces and entries. False plans removal. | `bool` | `true` | no |
| entries | Small configuration entries keyed by non-secret stable identifiers. namespace\_id accepts a managed namespace key or existing ID; key\_name defaults to the map key. Values are stored in state. | ```map(object({ account_id = optional(string) expiration = optional(number) expiration_ttl = optional(number) key_name = optional(string) metadata = optional(string) namespace_id = string value = string }))``` | `{}` | no |
| namespaces | Namespaces keyed by stable names. title defaults to the key. Jurisdiction and mode are creation-time choices. | ```map(object({ account_id = optional(string) jurisdiction = optional(string) mode = optional(string) title = optional(string) }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| entries | Complete entries, including stored values. Sensitive. |
| namespace\_ids | Namespace IDs for Worker bindings. |
| namespaces | Complete namespaces keyed by caller keys. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](../../docs/CONTRIBUTING.md) for local checks and contribution guidelines,
[UPGRADING.md](../../docs/UPGRADING.md) for adoption and acceptance checks, and the generated
[schema report](docs/SCHEMA.md) for provider coverage.

## Authors

Maintained by [Terraform Cloudflare Modules](https://github.com/terraform-cloudflare-modules).
See [AUTHORS](../../.github/AUTHORS) and [CODEOWNERS](../../.github/CODEOWNERS).

## License

MIT. See [LICENSE](../../LICENSE).
