# Binding alternatives

These objects replace or extend `script.bindings` in [main.tf](main.tf). They cover
all configurable binding fields in the v5.28.0 schema. Each type uses only its
corresponding fields. IDs/names below are explicit placeholders for resources you
must provision in the appropriate account. No storage, messaging, network, or AI
resource is created by adding a binding.

```hcl
bindings = [
  { name = "LABEL", type = "plain_text", text = "production" },
  { name = "TOKEN", type = "secret_text", text = "replace-with-secret-from-your-secret-source" },
  { name = "DB", type = "d1", id = "replace-with-d1-uuid", database_id = null },
  { name = "FILES", type = "r2_bucket", bucket_name = "existing-bucket", jurisdiction = "eu" },
  { name = "EVENTS", type = "queue", queue_name = "existing-queue" },
  { name = "ANALYTICS", type = "analytics_engine", dataset = "existing-dataset" },
  { name = "SEARCH", type = "vectorize", index_name = "existing-index" },
  { name = "AI_SEARCH", type = "ai_search", instance_name = "existing-instance", namespace = "default" },
  { name = "PIPELINE", type = "pipelines", pipeline = "existing-pipeline" },
  { name = "STREAM", type = "k2", stream = "replace-with-stream-id" },
  { name = "FLAGS", type = "flagship", app_id = "replace-with-app-id" },
  { name = "MTLS", type = "mtls_certificate", certificate_id = "replace-with-certificate-id" },
  { name = "STORED_SECRET", type = "secrets_store_secret", store_id = "replace-with-store-id", secret_name = "TOKEN" },
  { name = "WORKFLOW", type = "workflow", workflow_name = "existing-workflow" },
  { name = "BACKEND", type = "service", service = "existing-worker", entrypoint = "Backend", environment = null },
  { name = "INHERITED", type = "inherit", old_name = "PREVIOUS_NAME", version_id = "latest" },
  {
    name = "MAIL"
    type = "send_email"
    destination_address = null
    allowed_destination_addresses = ["alerts@example.com"]
    allowed_sender_addresses = ["worker@example.com"]
  },
  {
    name = "LIMITER"
    type = "ratelimit"
    namespace_id = "1001"
    simple = { limit = 100, period = 60, mitigation_timeout = 60 }
  },
  {
    name = "DISPATCH"
    type = "dispatch_namespace"
    namespace = "existing-dispatch-namespace"
    outbound = {
      params = [{ name = "tenant" }]
      worker = { service = "existing-outbound-worker", environment = "production", entrypoint = null }
    }
  },
  {
    name = "PRIVATE_SERVICE"
    type = "vpc_service"
    service_id = "replace-with-service-id"
  },
  {
    name = "PRIVATE_NETWORK"
    type = "vpc_network"
    network_id = "cf1:network"
    identity = "runtime-email-alpha"
    tunnel_id = null
  },
  {
    name = "SIGNING_KEY"
    type = "secret_key"
    algorithm = jsonencode({ name = "HMAC", hash = "SHA-256" })
    format = "raw"
    key_base64 = base64encode("replace-with-real-key-material")
    key_jwk = null
    usages = ["sign", "verify"]
  }
]
```

D1's `database_id` is an upstream alternative field; use the documented identifier
form for your installed provider/API. Email `destination_address` can restrict one
recipient instead of an allowed-recipient list. A VPC tunnel binding sets `tunnel_id`
and leaves `network_id` and `identity` null; Gateway identity needs the network form.
Connectivity and policies must already exist.

For a JWK secret key, use `format = "jwk"`, set `key_jwk` to the JSON-encoded JWK
document, and set `key_base64 = null`; the key data must match the declared algorithm.
Do not put real keys in checked-in examples. The module marks the entire script sensitive.

`part` applies only to legacy service-worker uploads, which the root does not create.
It remains exposed to preserve the upstream field; it is not a supported ES-module
binary import mechanism. A legacy binding object would be:

```hcl
{ name = "BINARY_DATA", type = "data_blob", part = "payload.bin" }
```

External Durable Object bindings use `script_name`, `class_name`, and optionally
`environment`/`dispatch_namespace`. The active example demonstrates local binding
and both `retry.max_attempts` and `retry.timeout_ms`. Inherit bindings require a
prior version with the referenced name; dispatch outbound and service entrypoints
must be exported by their target Workers.
