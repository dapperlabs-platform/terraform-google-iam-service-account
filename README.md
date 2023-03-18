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

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.8 |
| <a name="requirement_github"></a> [github](#requirement\_github) | >= 4.15.1 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.8 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_github"></a> [github](#provider\_github) | >= 4.15.1 |
| <a name="provider_google"></a> [google](#provider\_google) | n/a |
| <a name="provider_google-beta"></a> [google-beta](#provider\_google-beta) | n/a |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 2.8 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [github_actions_environment_variable.service_account_github_environment_variables](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_actions_environment_variable.workload_identity_provider_github_environment_variables](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_environment_variable) | resource |
| [github_actions_secret.repository_secret](https://registry.terraform.io/providers/integrations/github/latest/docs/resources/actions_secret) | resource |
| [google-beta_google_iam_workload_identity_pool.github_pool](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_iam_workload_identity_pool) | resource |
| [google-beta_google_iam_workload_identity_pool_provider.provider](https://registry.terraform.io/providers/hashicorp/google-beta/latest/docs/resources/google_iam_workload_identity_pool_provider) | resource |
| [google_billing_account_iam_member.billing-roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_account_iam_member) | resource |
| [google_folder_iam_member.folder-roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder_iam_member) | resource |
| [google_organization_iam_member.organization-roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_iam_member.project-roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_binding.roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_binding) | resource |
| [google_service_account_iam_member.github_service_account_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_service_account_key.key](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_key) | resource |
| [google_storage_bucket_iam_member.bucket-roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [kubernetes_secret.service-account-key-secret](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [google_project.project](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/project) | data source |
| [google_service_account.service_account](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | Display name of the service account to create. | `string` | `"Terraform-managed."` | no |
| <a name="input_generate_key"></a> [generate\_key](#input\_generate\_key) | Generate a key for service account. | `bool` | `false` | no |
| <a name="input_github_secret_create"></a> [github\_secret\_create](#input\_github\_secret\_create) | Create a Github Actions secret containing this service account's key | <pre>list(object({<br>    repository = string<br>    name       = string<br>  }))</pre> | `[]` | no |
| <a name="input_github_workload_identity_federation"></a> [github\_workload\_identity\_federation](#input\_github\_workload\_identity\_federation) | Workload identity federation configs for Github Actions | <pre>object({<br>    environment = optional(string, "")<br>    repository  = optional(string, "")<br>  })</pre> | `{}` | no |
| <a name="input_gke_secret_create"></a> [gke\_secret\_create](#input\_gke\_secret\_create) | Create GKE Opaque secret containing this service account's key as key.json | <pre>object({<br>    namespace = string<br>  })</pre> | `null` | no |
| <a name="input_iam"></a> [iam](#input\_iam) | IAM bindings on the service account in {ROLE => [MEMBERS]} format. | `map(list(string))` | `{}` | no |
| <a name="input_iam_billing_roles"></a> [iam\_billing\_roles](#input\_iam\_billing\_roles) | Project roles granted to the service account, by billing account id. | `map(list(string))` | `{}` | no |
| <a name="input_iam_folder_roles"></a> [iam\_folder\_roles](#input\_iam\_folder\_roles) | Project roles granted to the service account, by folder id. | `map(list(string))` | `{}` | no |
| <a name="input_iam_organization_roles"></a> [iam\_organization\_roles](#input\_iam\_organization\_roles) | Project roles granted to the service account, by organization id. | `map(list(string))` | `{}` | no |
| <a name="input_iam_project_roles"></a> [iam\_project\_roles](#input\_iam\_project\_roles) | Project roles granted to the service account, by project id. | `map(list(string))` | `{}` | no |
| <a name="input_iam_storage_roles"></a> [iam\_storage\_roles](#input\_iam\_storage\_roles) | Storage roles granted to the service account, by bucket name. | `map(list(string))` | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the service account to create. | `string` | n/a | yes |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | Prefix applied to service account names. | `string` | `null` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | Project id where service account will be created. | `string` | n/a | yes |
| <a name="input_service_account_create"></a> [service\_account\_create](#input\_service\_account\_create) | Create service account. When set to false, uses a data source to reference an existing service account. | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_email"></a> [email](#output\_email) | Service account email. |
| <a name="output_github_pool_provider_id"></a> [github\_pool\_provider\_id](#output\_github\_pool\_provider\_id) | Identifier for the Github provider |
| <a name="output_iam_email"></a> [iam\_email](#output\_iam\_email) | IAM-format service account email. |
| <a name="output_key"></a> [key](#output\_key) | Service account key. |
| <a name="output_service_account"></a> [service\_account](#output\_service\_account) | Service account resource. |
