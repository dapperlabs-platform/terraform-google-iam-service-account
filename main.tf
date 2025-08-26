/**
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  iam_billing_pairs = flatten([
    for entity, roles in var.iam_billing_roles : [
      for role in roles : [
        { entity = entity, role = role }
      ]
    ]
  ])
  iam_folder_pairs = flatten([
    for entity, roles in var.iam_folder_roles : [
      for role in roles : [
        { entity = entity, role = role }
      ]
    ]
  ])
  iam_organization_pairs = flatten([
    for entity, roles in var.iam_organization_roles : [
      for role in roles : [
        { entity = entity, role = role }
      ]
    ]
  ])
  iam_project_pairs = flatten([
    for entity, roles in var.iam_project_roles : [
      for role in roles : [
        { entity = entity, role = role }
      ]
    ]
  ])
  iam_project_pairs_conditions = flatten([
    for entity, roles in var.iam_project_roles_conditions : [
      for role_binding in roles : {
        entity = entity
        role   = role_binding.role

        condition = try(role_binding.condition, null)
      }
    ]
  ])

  iam_storage_pairs = flatten([
    for entity, roles in var.iam_storage_roles : [
      for role in roles : [
        { entity = entity, role = role }
      ]
    ]
  ])
  generate_key = var.generate_key || var.gke_secret_create != null || length(var.github_secret_create) > 0
  # https://github.com/hashicorp/terraform/issues/22405#issuecomment-591917758
  key = try(
    local.generate_key
    ? google_service_account_key.key["1"]
    : map("", null)
  , {})
  prefix                    = var.prefix != null ? "${var.prefix}-" : ""
  account_id                = "${local.prefix}${var.name}"
  resource_email_static     = "${local.prefix}${var.name}@${var.project_id}.iam.gserviceaccount.com"
  resource_iam_email_static = "serviceAccount:${local.resource_email_static}"
  resource_iam_email        = local.resource_iam_email_static
  service_account = (
    var.service_account_create
    ? try(google_service_account.service_account.0, null)
    : try(data.google_service_account.service_account.0, null)
  )
}

data "google_service_account" "service_account" {
  count      = var.service_account_create ? 0 : 1
  project    = var.project_id
  account_id = local.account_id
}

resource "google_service_account" "service_account" {
  count        = var.service_account_create ? 1 : 0
  project      = var.project_id
  account_id   = local.account_id
  display_name = var.display_name
}

resource "google_service_account_key" "key" {
  for_each           = local.generate_key ? { 1 = 1 } : {}
  service_account_id = local.service_account.email
}

resource "google_service_account_iam_binding" "roles" {
  for_each           = var.iam
  service_account_id = local.service_account.name
  role               = each.key
  members            = each.value
}

resource "google_billing_account_iam_member" "billing-roles" {
  for_each = {
    for pair in local.iam_billing_pairs :
    "${pair.entity}-${pair.role}" => pair
  }
  billing_account_id = each.value.entity
  role               = each.value.role
  member             = local.resource_iam_email
}

resource "google_folder_iam_member" "folder-roles" {
  for_each = {
    for pair in local.iam_folder_pairs :
    "${pair.entity}-${pair.role}" => pair
  }
  folder = each.value.entity
  role   = each.value.role
  member = local.resource_iam_email
}

resource "google_organization_iam_member" "organization-roles" {
  for_each = {
    for pair in local.iam_organization_pairs :
    "${pair.entity}-${pair.role}" => pair
  }
  org_id = each.value.entity
  role   = each.value.role
  member = local.resource_iam_email
}

resource "google_project_iam_member" "project-roles" {
  for_each = {
    for pair in local.iam_project_pairs :
    "${pair.entity}-${pair.role}" => pair
  }
  project = each.value.entity
  role    = each.value.role
  member  = local.resource_iam_email
}

resource "google_project_iam_member" "project-roles-conditions" {
  for_each = {
    for pair in local.iam_project_pairs_conditions :
    "${pair.entity}-${pair.role}" => pair
  }

  project = each.value.entity
  role    = each.value.role
  member  = local.resource_iam_email

  condition {
    expression  = each.value.condition.expression
    title       = each.value.condition.title
    description = try(each.value.condition.description, "")
  }
}

resource "google_storage_bucket_iam_member" "bucket-roles" {
  for_each = {
    for pair in local.iam_storage_pairs :
    "${pair.entity}-${pair.role}" => pair
  }
  bucket = each.value.entity
  role   = each.value.role
  member = local.resource_iam_email
}

resource "kubernetes_secret" "service-account-key-secret" {
  count = var.gke_secret_create == null ? 0 : 1
  type  = "kubernetes.io/opaque"
  metadata {
    name      = "${local.prefix}${var.name}-service-account-key"
    namespace = var.gke_secret_create.namespace
  }

  binary_data = {
    "key.json" = local.key.private_key
  }
}

resource "github_actions_secret" "repository_secret" {
  count           = length(var.github_secret_create)
  repository      = var.github_secret_create[count.index].repository
  secret_name     = var.github_secret_create[count.index].name
  plaintext_value = local.key.private_key
}
