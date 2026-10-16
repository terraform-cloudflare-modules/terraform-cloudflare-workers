resource "terraform_data" "upstream" {
  input = { account_id = "0123456789abcdef0123456789abcdef", namespace_id = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", value = "payload" }
}
module "kv" {
  source     = "../../.."
  account_id = terraform_data.upstream.output.account_id
  entries    = { config = { namespace_id = terraform_data.upstream.output.namespace_id, value = terraform_data.upstream.output.value } }
}
output "keys" {
  description = "Known keys for unknown-input plan assertions."
  value       = nonsensitive(keys(module.kv.entries))
}
