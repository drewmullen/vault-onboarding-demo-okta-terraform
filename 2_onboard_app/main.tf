locals {
  enumeration = flatten([for env in var.environments: [
    for perm in ["rw", "ro"]: "${env}-${perm}"
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
    local.policies[each.value]
  ]

  metadata = {
    app_id = var.app_id
    app_name = var.app_name
    environment = "dev"
  }
}

locals {
  policies = {
    "dev-rw" = vault_policy.dev_rw.name
    "dev-ro" = vault_policy.dev_ro.name
    "prod-rw" = vault_policy.prod_rw.name
    "prod-ro" = vault_policy.prod_ro.name
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


data "vault_policy_document" "prod_rw" {
  rule {
    path         = "${var.bu}/${var.lob}/${var.app_id}/prod/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow all on secrets for ${var.app_id} in prod"
  }
}

data "vault_policy_document" "dev_rw" {
  rule {
    path         = "${var.bu}/${var.lob}/${var.app_id}/dev/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow all on secrets for ${var.app_id} in dev"
  }
}

data "vault_policy_document" "prod_ro" {
  rule {
    path         = "${var.bu}/${var.lob}/${var.app_id}/prod/*"
    capabilities = ["create", "read", "update", "delete", "list"]
    description  = "allow all on secrets for ${var.app_id} in prod"
  }
}

data "vault_policy_document" "dev_ro" {
  rule {
    path         = "${var.bu}/${var.lob}/${var.app_id}/dev/*"
    capabilities = ["read","list"]
    description  = "read all on secrets for ${var.app_id} in dev"
  }
}

resource "vault_policy" "prod_rw" {
  name   = "vault-${var.app_id}-prod-rw"
  policy = data.vault_policy_document.prod_rw.hcl
}

resource "vault_policy" "dev_rw" {
  name   = "vault-${var.app_id}-dev-rw"
  policy = data.vault_policy_document.dev_rw.hcl
}

resource "vault_policy" "prod_ro" {
  name   = "vault-${var.app_id}-prod-ro"
  policy = data.vault_policy_document.prod_ro.hcl
}

resource "vault_policy" "dev_ro" {
  name   = "vault-${var.app_id}-dev-ro"
  policy = data.vault_policy_document.dev_ro.hcl
}

data "okta_app_oauth" "default" {
  label = "HashiCorp Vault OIDC"
}

resource "okta_app_group_assignment" "enumeration" {
  for_each = toset(local.enumeration)
  app_id   = data.okta_app_oauth.default.id
  group_id = okta_group.enumeration[each.key].id
}