mock_provider "cloudflare" {}
run "unknown_values_keep_stable_resource_addresses" {
  command = plan
  module { source = "./tests/fixtures/unknown" }
  assert {
    condition     = output.route_keys == ["api"] && output.domain_keys == ["api"]
    error_message = "Computed account IDs, zone IDs, secrets, schedules, and version IDs must not control resource addresses."
  }
}
