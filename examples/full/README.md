# Complete Workers configuration

[main.tf](main.tf) shows every top-level input and the nested settings suitable for
a single application. Supply the account, an existing zone ID/name, and optionally
an existing tail consumer. The account needs Workers, KV, Durable Objects, static
assets, Smart Placement, and any preview/observability features selected. Replace
or remove unsupported optional settings for your account. The route hostname needs
existing proxied DNS; the custom domain uses a separate hostname without a conflicting
record. The example does not configure your account's workers.dev subdomain.

The Worker serves static assets, exposes a persistent counter, and reads shared
configuration on a cron schedule. Both KV and Durable Objects retain application
state. Removing or renaming these resources is not a harmless demonstration reset.
Optional nulls and empty collections are deliberate. Use the substitutions below
for mutually exclusive alternatives, rather than combining all settings in one call.

## Bindings

The active example uses assets, KV, JSON, and a local Durable Object. The separate
[binding alternatives](bindings.md) demonstrate every remaining binding field and
its external prerequisites. Replace or extend `script.bindings` with the relevant
objects; do not enable every binding just to mirror the reference.

## Placement, packages, and containers

Both `worker.previews_base_config.placement` and `script.placement` accept the same
shape. Instead of smart placement, use a targeted placement appropriate to the account:

```hcl
placement = {
  mode = "targeted"
  host = null
  hostname = null
  region = null
  target = [{ host = null, hostname = null, region = "aws:eu-west-1" }]
}
```

A TCP `host`, HTTP `hostname`, and regional target are alternatives. The top-level
host/hostname/region forms are also exposed; do not combine them with a target list.
A tail consumer must already exist and implement the tail handler.

`package_dependencies` describes a real, prebuilt artifact; it does not install dependencies:

```hcl
package_dependencies = [{
  name                 = "your-built-package"
  installed_version    = "1.2.3"
  package_json_version = "^1.2.0"
}]
```

For Containers, export the appropriate container Durable Object class in your built
code, provision its container application externally, then use
`containers = [{ class_name = "ContainerClass" }]`. This example does not provision it.

## Durable Object lifecycle alternatives

The main configuration uses declarative `exports`. `state = "created"` with
`storage = "sqlite"` provisions a live Durable Object class. A rename uses
`state = "renamed"` and `renamed_to` pointing to another live export; a transfer uses
`state = "transferred"` and `transferred_to`. The receiving script uses
`state = "expecting-transfer"`, `storage`, and `transfer_from`. These operations
require existing matching classes, script ownership, and a coordinated rollout.
The provider omits completed tombstones on reads, so inspect subsequent plans.

For a migration-based workflow, set `exports = null` and substitute the matching
migration instead. The following shows every field; use only the operations that
match your existing namespaces and code. Top-level operations and ordered `steps`
are alternative representations, not duplicate instructions for the same class:

```hcl
migrations = {
  old_tag            = "v1"
  new_tag            = "v2"
  deleted_classes    = ["RetiredClass"]
  new_classes        = ["LegacyCounter"]
  new_sqlite_classes = ["Counter"]
  renamed_classes    = [{ from = "OldClass", to = "RenamedClass" }]
  transferred_classes = [{
    from        = "SourceClass"
    from_script = "existing-source-worker"
    to          = "ImportedClass"
  }]
  steps = null
}
```

An ordered-step alternative sets those five top-level operation lists to null:

```hcl
migrations = {
  old_tag = "v1"
  new_tag = "v2"
  steps = [{
    deleted_classes    = ["RetiredClass"]
    new_classes        = ["LegacyCounter"]
    new_sqlite_classes = ["Counter"]
    renamed_classes    = [{ from = "OldClass", to = "RenamedClass" }]
    transferred_classes = [{
      from        = "SourceClass"
      from_script = "existing-source-worker"
      to          = "ImportedClass"
    }]
  }]
}
```

Deletion removes namespace data. Do not apply these illustrative migrations unchanged.
Migrations apply at deployment; declarative export reconciliation can act at upload.
Consult the [version documentation](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/docs/resources/worker_version.md)
before adopting either lifecycle model.

## Deployment and ownership alternatives

Use `script.deploy = true` only with `create_deployment = false`. For a gradual
rollout, keep separate deployment ownership and replace its versions list with
`current` plus actual previous version UUIDs whose percentages total 100. Do not
reference this module's own output in its input. Existing versions must be compatible
with the same asset base path and stateful bindings.

Use `create_worker = false` and `worker = {}` for an already-owned Worker. Set
`create_version = false` to leave uploads elsewhere, and use literal external IDs
if managing deployments. `create_schedules = true` with `schedules = []` clears
all schedules; false does not safely transfer existing state ownership.
