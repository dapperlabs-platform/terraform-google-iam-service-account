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

data "google_project" "project" {
}

output "service_account" {
  description = "Service account resource."
  value       = local.service_account
}

output "email" {
  description = "Service account email."
  value       = local.resource_email_static
  depends_on = [
    local.service_account
  ]
}

output "iam_email" {
  description = "IAM-format service account email."
  value       = local.resource_iam_email_static
  depends_on = [
    local.service_account
  ]
}

output "key" {
  description = "Service account key."
  sensitive   = true
  value       = local.key
}

output "github_pool_provider_id" {
  description = "Identifier for the Github provider"
  value       = local.add_github_workload_identity_federation ? replace(google_iam_workload_identity_pool_provider.provider[0].id, var.project_id, data.google_project.project.number) : ""
}
