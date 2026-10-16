# Shared KV namespaces and entries

Every KV submodule input is shown in [main.tf](main.tf). Supply the account ID and
an existing namespace ID in that account. The example creates a classic namespace
restricted to EU storage and owns one entry in that namespace plus one in the
external namespace. KV mode and jurisdiction changes can replace the namespace;
use `mode = "instant"` only when deliberately creating an eligible KV Instant namespace.

The entries demonstrate relative and absolute expiration. Expired Terraform-owned
entries may be recreated during a later apply, so manage application TTL data outside
Terraform. Replace the absolute timestamp with your intended expiration time.
Explicit per-entry account settings override the module default. The external
namespace itself is not adopted or destroyed by this call.
