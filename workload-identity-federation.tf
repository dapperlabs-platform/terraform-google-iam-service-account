locals {
  github_repository = var.github_workload_identity_federation.repository
  # github_actions_environment_variable expects repo name only, owner is inferred by the provider
  repo_name                               = split("/", local.github_repository)[1]
  github_environment                      = var.github_workload_identity_federation.environment
  add_github_workload_identity_federation = length(compact([local.github_repository, local.github_environment])) == 2 ? 1 : 0
  github_pool_id                          = substr("${split("/", local.github_repository)[1]}-${var.name}", 0, 32)
  # only allow workflows from this repository/environment combination to impersonate this service account
  github_attribute_condition = "assertion.repository == \"${local.github_repository}\" && assertion.environment == \"${local.github_environment}\""
  github_issuer_uri          = "https://token.actions.githubusercontent.com"
  formatted_account_id       = upper(replace(local.account_id, "-", "_"))
}

resource "google_iam_workload_identity_pool" "github_pool" {
  count    = local.add_github_workload_identity_federation
  provider = google-beta

  project                   = var.project_id
  workload_identity_pool_id = local.github_pool_id
  display_name              = local.github_pool_id
  description               = "Workload Identity Federation Pool managed by Terraform"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  count    = local.add_github_workload_identity_federation
  provider = google-beta

  project                            = var.project_id
  attribute_condition                = local.github_attribute_condition
  description                        = "Workload Identity Federation Pool Provider managed by Terraform"
  disabled                           = false
  display_name                       = local.github_pool_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = local.github_pool_id

  attribute_mapping = {
    "google.subject" = "assertion.sub",
  }

  oidc {
    issuer_uri = local.github_issuer_uri
  }
}

resource "google_service_account_iam_member" "github_service_account_user" {
  count = local.add_github_workload_identity_federation

  service_account_id = local.service_account.name
  # Allow all principals that match the provider's condition to impersonate this service account
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/*"
  role   = "roles/iam.workloadIdentityUser"
}

resource "github_actions_environment_variable" "service_account_github_environment_variable" {
  count         = local.add_github_workload_identity_federation
  repository    = local.repo_name
  environment   = local.github_environment
  variable_name = "${local.formatted_account_id}_SERVICE_ACCOUNT"
  value         = local.service_account.email
}

resource "github_actions_environment_variable" "workload_identity_provider_github_environment_variable" {
  count         = local.add_github_workload_identity_federation
  repository    = local.repo_name
  environment   = local.github_environment
  variable_name = "${local.formatted_account_id}_WORKLOAD_IDENTITY_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.provider[0].name
}
