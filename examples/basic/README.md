# Deploy a Worker from a file

Supply `account_id` for an account with Workers access and an already registered
workers.dev subdomain. The example owns Worker metadata, uploads [worker.js](worker.js),
and deploys it at 100%. Changing the file creates a new version.

See [main.tf](main.tf) and [variables.tf](variables.tf). No DNS zone or live test
infrastructure is created by the test suite.
