locals {
  okta_issuer = "https://integrator-3678783.okta.com/oauth2/default"
}

data "okta_auth_server" "example" {
  name = "default"
}

output "default_auth_server_id" {
  value = data.okta_auth_server.example.id
}

resource "okta_auth_server_claim" "groups" {
  auth_server_id = data.okta_auth_server.example.id
  name           = "groups"
  value          = "vault-"
  always_include_in_token = false
  claim_type = "IDENTITY"
  value_type = "GROUPS"
  group_filter_type = "STARTS_WITH"
}

resource "okta_auth_server_policy" "example" {
  auth_server_id   = data.okta_auth_server.example.id
  status           = "ACTIVE"
  name             = "vault"
  description      = "vault login"
  priority         = 1
  client_whitelist = ["ALL_CLIENTS"]
}

resource "okta_auth_server_policy_rule" "example" {
  auth_server_id       = data.okta_auth_server.example.id
  policy_id            = okta_auth_server_policy.example.id
  status               = "ACTIVE"
  name                 = "vault"
  priority             = 1
  group_whitelist      = ["EVERYONE"]
  grant_type_whitelist = ["authorization_code", "client_credentials", "implicit"]
  scope_whitelist = [ "*" ]
}

resource "okta_auth_server_scope" "groups" {
  auth_server_id   = data.okta_auth_server.example.id
  metadata_publish = "NO_CLIENTS"
  name             = "groups"
  consent          = "IMPLICIT"
  description = "expose user groups in id token"
  display_name = "groups"
}

resource "okta_app_oauth" "default" {
  label          = "HashiCorp Vault OIDC"
  type           = "web"
  grant_types    = ["authorization_code", "implicit", "refresh_token"]
  response_types = ["id_token", "code"]
  issuer_mode = "DYNAMIC"

  redirect_uris = [
    format("%s/ui/vault/auth/okta/oidc/callback", var.vault_addr),
    "http://localhost:8250/oidc/callback"
  ]
}

resource "okta_app_oauth_api_scope" "default" {
  app_id = okta_app_oauth.default.id
  issuer = "https://${var.okta_org_name}.${var.okta_base_url}"
  scopes = ["okta.groups.read", "okta.users.read.self"]
}
