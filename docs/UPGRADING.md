# Adoption and verification

This repository starts a new module API; it is not a state-compatible replacement
for an existing `cloudflare_workers_script` wrapper. No remote repository or module
publication is assumed. Create/connect the approved GitHub repository separately,
run native CI, and review release and Registry setup before publishing.

## Ownership

Use one owner for Worker metadata, one for the version/deployment pipeline, one for
each route/domain, and one for the complete cron list. External code deployment can
coexist with metadata ownership only if it does not write the same configuration.
Use `create_worker = false` to attach resources to an existing Worker by name.
Importing metadata does not import versions, domains, routes, or schedules.

For an existing Worker, add matching configuration before importing:

```hcl
import {
  to = module.worker.cloudflare_worker.this[0]
  id = "ACCOUNT_ID/WORKER_ID"
}
```

The [provider's version import](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/docs/resources/worker_version.md)
uses `ACCOUNT_ID/WORKER_ID/VERSION_ID`. Match all upload settings before adopting a
version, and review replacement plans. Use provider-specific import IDs for routes,
domains, cron triggers, deployments, and KV resources. Never import one remote object
into multiple active owners.

For equivalent resources already in the same state, use a caller-root moved block:

```hcl
moved {
  from = cloudflare_workers_route.api
  to   = module.worker.cloudflare_workers_route.this["api"]
}
```

Do not move a legacy script directly to a different resource type. Stage metadata,
version, and deployment adoption using the installed provider's supported imports.
Before removing configuration, review references, cron triggers, Durable Object
state, KV data, and DNS consumers. False creation flags plan destruction, not a
state-only transfer. Avoid force deletion while other Workers reference a service.

## Local checks

Run the repository pre-commit hooks and the native mocked tests with Terraform and
OpenTofu. Initialize the root and `modules/kv`, then run `terraform test` in each;
the equivalent `tofu` commands are supported. CI also validates examples and fixtures.
No cloud credentials or live resources are needed for native mock tests, but the
provider executable must be able to start its local plugin socket.

Generate and check the Formr reports with a fresh provider schema:

```sh
formr schema . -o docs/SCHEMA.md
formr check . --report docs/SCHEMA.md
formr schema modules/kv -o modules/kv/docs/SCHEMA.md
formr check modules/kv --report modules/kv/docs/SCHEMA.md
```

For the existing raw snapshot, append `--schema-file secrets/schema.json` to these
commands. This preserves the explicit missing-provenance diagnostic. Do not commit
the snapshot or credentials. Formr's `one(...)` tracing limitation can classify
exported singleton attributes as unused; whole-object outputs preserve them.

## Acceptance before release

In a dedicated test account, verify Worker creation, an uploaded ES module, a second
no-change plan, a code update, deployment percentage changes and rollback. Exercise
routes, exclusions, custom-domain activation, scheduled events, and deletion order.
Test static asset changes and sensitive binding updates. Durable Object migrations,
preview settings, KV mode/jurisdiction changes, and retention require their own
entitled-account checks. Mock tests cannot establish live API semantics.
