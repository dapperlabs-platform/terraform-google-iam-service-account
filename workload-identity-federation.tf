locals {
  workload_identity_federation_configs = {
    for o in var.github_workload_identity_federation : "${o.repository}/${o.environment}" => merge(o, {
      # github_actions_environment_variable expects repo name only, owner is inferred by the provider
      repo_name = split("/", o.repository)[1]
      pool_id   = substr("${split("/", o.repository)[1]}-${var.name}", 0, 32)
    }) if length(compact([o.repository, o.environment])) == 2
  }

  github_issuer_uri    = "https://token.actions.githubusercontent.com"
  formatted_account_id = upper(replace(local.account_id, "-", "_"))
}

resource "github_repository_environment" "environments" {
  for_each = {
    for k, v in local.workload_identity_federation_configs : k => v if v.create_environment
  }

  repository  = each.value.repo_name
  environment = each.value.environment

  dynamic "reviewers" {
    for_each = try(each.value.environment_config.reviewers, [])
    content {
      users = try(reviewers.value.users, null)
      teams = try(reviewers.value.teams, null)
    }
  }

  wait_timer          = try(each.value.environment_config.wait_timer, 0)
  can_admins_bypass   = try(each.value.environment_config.can_admins_bypass, true)
  prevent_self_review = try(each.value.environment_config.prevent_self_review, false)

  dynamic "deployment_branch_policy" {
    for_each = try(each.value.environment_config.deployment_branch_policy, null) != null ? [each.value.environment_config.deployment_branch_policy] : []
    content {
      protected_branches     = deployment_branch_policy.value.protected_branches
      custom_branch_policies = deployment_branch_policy.value.custom_branch_policies
    }
  }
}

resource "google_iam_workload_identity_pool" "github_pools" {
  for_each = local.workload_identity_federation_configs
  provider = google-beta

  project                   = var.project_id
  workload_identity_pool_id = each.value.pool_id
  display_name              = each.value.pool_id
  description               = "Workload Identity Federation Pool managed by Terraform"
  disabled                  = false
}

resource "google_iam_workload_identity_pool_provider" "providers" {
  for_each = local.workload_identity_federation_configs
  provider = google-beta

  project                            = var.project_id
  attribute_condition                = "assertion.repository == \"${each.value.repository}\" && assertion.environment == \"${each.value.environment}\""
  description                        = "Workload Identity Federation Pool Provider managed by Terraform"
  disabled                           = false
  display_name                       = each.value.pool_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pools[each.key].workload_identity_pool_id
  workload_identity_pool_provider_id = each.value.pool_id

  attribute_mapping = {
    "google.subject" = "assertion.sub",
  }

  oidc {
    issuer_uri = local.github_issuer_uri
  }
}

resource "google_service_account_iam_member" "github_service_account_users" {
  for_each = local.workload_identity_federation_configs

  service_account_id = local.service_account.name
  # Allow all principals that match the provider's condition to impersonate this service account
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pools[each.key].name}/*"
  role   = "roles/iam.workloadIdentityUser"
}

resource "github_actions_environment_variable" "service_account_github_environment_variables" {
  for_each      = local.workload_identity_federation_configs
  repository    = each.value.repo_name
  environment   = each.value.environment
  variable_name = "${local.formatted_account_id}_SERVICE_ACCOUNT"
  value         = local.service_account.email
  depends_on    = [github_repository_environment.environments]
}

resource "github_actions_environment_variable" "workload_identity_provider_github_environment_variables" {
  for_each      = local.workload_identity_federation_configs
  repository    = each.value.repo_name
  environment   = each.value.environment
  variable_name = "${local.formatted_account_id}_WORKLOAD_IDENTITY_PROVIDER"
  value         = google_iam_workload_identity_pool_provider.providers[each.key].name
  depends_on    = [github_repository_environment.environments]
}
