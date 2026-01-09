locals {
  enumeration = flatten([for env in var.environments: [
    for perm in keys(var.policies): "${env}-${perm}"
]])
}

resource "okta_group" "enumeration" {
  for_each = toset(local.enumeration)

  name        = "vault-${var.app_id}-${each.value}"
  description = "${each.value} Group for ${var.app_id}"
}

resource "vault_identity_group" "enumeration" {
  for_each = toset(local.enumeration)

  name     = "${var.app_id}-${each.value}"
  type     = "external"
  
  policies = [
    vault_policy.enumeration[each.value].name
  ]

  metadata = {
    app_id = var.app_id
    app_name = var.app_name
    environment = "dev"
  }
}

data "vault_auth_backend" "okta" {
  path = "okta"
}

resource "vault_identity_group_alias" "enumeration" {
  for_each = toset(local.enumeration)

  name           = "vault-${var.app_id}-${each.value}"
  canonical_id   = vault_identity_group.enumeration[each.value].id
  mount_accessor = data.vault_auth_backend.okta.accessor
}

data "vault_policy_document" "enumeration" {
  for_each = toset(local.enumeration)

  rule {
    path         = "${var.bu}/${var.lob}/${var.app_id}/${split("-", each.key)[0]}/*"
    capabilities = var.policies[split("-", each.value)[1]]
    description  = "allow  on secrets for ${var.app_id} in ${each.value}"
  }
}

resource "vault_policy" "enumeration" {
  for_each = toset(local.enumeration)

  name   = "vault-${var.app_id}-${each.value}"
  policy = data.vault_policy_document.enumeration[each.value].hcl
}

data "okta_app_oauth" "default" {
  label = "HashiCorp Vault OIDC"
}

resource "okta_app_group_assignment" "enumeration" {
  for_each = toset(local.enumeration)
  app_id   = data.okta_app_oauth.default.id
  group_id = okta_group.enumeration[each.key].id
}