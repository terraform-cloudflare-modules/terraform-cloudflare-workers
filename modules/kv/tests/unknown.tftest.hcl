mock_provider "cloudflare" {}
run "unknown_sensitive_values_preserve_entry_keys" {
  command = plan
  module { source = "./tests/fixtures/unknown" }
  assert {
    condition     = output.keys == ["config"]
    error_message = "Only non-secret caller keys may control resource addresses."
  }
}
