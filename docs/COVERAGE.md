# Workers coverage and product boundaries

Research baseline: Cloudflare provider **5.28.0**, verified against the upstream
[latest release](https://github.com/cloudflare/terraform-provider-cloudflare/releases/tag/v5.28.0)
on 2026-10-17. Its release adds Durable Object binding retries and KV namespace mode;
both are exposed here. Requirements match the DNS repository: Terraform >= 1.8 and
Cloudflare >= 5.28.0, < 6.0.0. Retest provider upgrades before release.

## Implemented ownership

| Resource | Owner and purpose |
| --- | --- |
| `cloudflare_worker` | Root: identity, metadata, observability, preview defaults, workers.dev controls, tags, tail consumers. |
| `cloudflare_worker_version` | Root: code/assets upload, bindings, compatibility, limits, placement, exports or migrations. |
| `cloudflare_workers_deployment` | Root: traffic percentages across the uploaded and/or existing versions. |
| `cloudflare_workers_route` | Root: zone patterns and exclusion routes. |
| `cloudflare_workers_custom_domain` | Root: Worker custom domains. |
| `cloudflare_workers_cron_trigger` | Root: complete cron schedule ownership. |
| `cloudflare_workers_kv_namespace` | KV submodule: independently shared namespaces. |
| `cloudflare_workers_kv` | KV submodule: small Terraform-owned configuration entries. |

Every configurable field of these resources is represented. Account IDs and Worker
references are intentionally shared within a root invocation; a route's optional script
is controlled by the Worker name and bypass flag. Full provider objects are returned.
This is resource-interface coverage, not a claim that every combination or account
entitlement has been live-tested.

The raw schema supplied in the DNS workspace was reused and cross-checked against
versioned upstream documentation. It has no engine/provider provenance wrapper;
[SCHEMA.md](SCHEMA.md) records that limitation rather than inventing provenance.

## Explicit boundaries and omissions

| Area | Initial scope and future direction |
| --- | --- |
| Legacy script resource | `cloudflare_workers_script` is not owned. The root uses the separate Worker/version/deployment model recommended in its documentation. Legacy service-worker syntax and dispatch-script uploads need a separate adoption path. |
| Separate script subdomain | `cloudflare_workers_script_subdomain` is not owned because `worker.subdomain` owns that configuration. Do not combine both owners. Account workers.dev subdomain registration is outside this module. |
| Workers for Platforms | `cloudflare_workers_for_platforms_dispatch_namespace` and tenant dispatch scripts are deferred to a separate submodule. Dispatch bindings can reference an existing namespace; creating a namespace alone would not implement the tenant lifecycle. |
| Workflows | `cloudflare_workflow` is available upstream but not managed yet. Its bindings can reference externally owned workflows. Provisioning and operational workflow runs need separate design. |
| Durable Objects | Bindings, exports, and migration metadata are included. There is no standalone Durable Object namespace resource in the inspected provider schema. Runtime data and migrations between applications are not automated. |
| Containers | Class attachment metadata is exposed. The inspected schema has no container application resource; image builds, registry upload, and container application provisioning are not claimed. |
| R2, D1, Queues, Hyperdrive | Bindings reference externally owned resources. Buckets/databases/queues/consumers/connections are separate product lifecycles and are not implicitly created. |
| AI, Vectorize, Analytics Engine, Pipelines, Images, Browser, Secrets Store | Existing-resource bindings are accepted where supported by the provider. Creating or operating these products is outside the initial module. |
| Pages | Pages projects and domains are a different application/deployment model and are excluded. |
| DNS and Zero Trust | DNS zones/records remain in the DNS module. Gateway, Access, Tunnel, VPC connectivity and policies remain separately owned. Binding their identifiers does not configure connectivity or policy. |
| Runtime operations | No package installation, bundling, Wrangler invocation, code builds, event consumption, KV bulk data synchronization, or live tests. Supply built artifacts and manage application data outside Terraform. |

The next Workers-specific additions are a coherent dispatch submodule and Workflow
resource ownership. Both should follow account-level reuse and explicit code ownership
rather than being added to every Worker invocation.

## Primary references

- [Worker resource](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/docs/resources/worker.md)
- [Version resource](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/docs/resources/worker_version.md)
- [Deployment resource](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/docs/resources/workers_deployment.md)
- [Legacy script and recommended model](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/workers_script)
- [Version schema and replacement behavior](https://github.com/cloudflare/terraform-provider-cloudflare/blob/v5.28.0/internal/services/worker_version/schema.go)
