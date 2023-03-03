locals {
  add_github_workload_identity_federation = length(compact([var.github_workload_identity_federation.repository, var.github_workload_identity_federation.environment])) == 2
  github_repository                       = var.github_workload_identity_federation.repository
  github_environment                      = var.github_workload_identity_federation.environment
  github_pool_id                          = local.add_github_workload_identity_federation ? substr("${split("/", var.github_workload_identity_federation.repository)[1]}-${var.name}", 0, 32) : ""
  # only allow workflows from this repository/environment combination to impersonate this service account
  github_attribute_condition = "assertion.repository == \"${local.github_repository}\" && assertion.environment == \"${local.github_environment}\""
  github_issuer_uri          = "https://token.actions.githubusercontent.com"
}

resource "google_iam_workload_identity_pool" "github_pool" {
  count    = local.add_github_workload_identity_federation ? 1 : 0
  provider = google-beta

  project                   = var.project_id
  workload_identity_pool_id = local.github_pool_id
  display_name              = local.github_pool_id
  description               = "Workload Identity Federation Pool managed by Terraform"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "provider" {
  count    = local.add_github_workload_identity_federation ? 1 : 0
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
  count = local.add_github_workload_identity_federation ? 1 : 0

  service_account_id = "projects/${var.project_id}/serviceAccounts/${local.resource_email_static}"
  # Allow all principals that match the provider's condition to impersonate this service account
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool[0].name}/*"
  role   = "roles/iam.workloadIdentityUser"
}
