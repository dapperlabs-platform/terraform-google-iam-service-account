# Google Service Account Module

This module allows simplified creation and management of one a service account and its IAM bindings. A key can optionally be generated and will be stored in Terraform state. To use it create a sensitive output in your root modules referencing the `key` output, then extract the private key from the JSON formatted outputs.

A Github workload identity pool and provider can also be created by setting `github_workload_identity_federation`. The module will also create `<service-account-name>_SERVICE_ACCOUNT` and `<service-account-name>_WORKLOAD_IDENTITY_PROVIDER` Github Environment variables that you can reference from your Github Actions Workflow.

## Example

```hcl
module "myproject-default-service-accounts" {
  source            = "github.com/dapperlabs-platform/terraform-google-iam-service-account?ref=tag"
  project_id        = "myproject"
  name              = "vm-default"
  generate_key      = true
  # authoritative roles granted *on* the service accounts to other identities
  iam       = {
    "roles/iam.serviceAccountUser" = ["user:foo@example.com"]
  }
  # non-authoritative roles granted *to* the service accounts on other resources
  iam_project_roles = {
    "myproject" = [
      "roles/logging.logWriter",
      "roles/monitoring.metricWriter",
    ]
  }
}
```
