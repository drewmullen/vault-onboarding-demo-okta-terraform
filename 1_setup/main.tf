locals {
  okta_issuer = "https://integrator-3678783.okta.com/oauth2/default"
  auth_path   = "okta"
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

resource "vault_jwt_auth_backend" "okta" {
  path                = local.auth_path
  type                = "oidc"
  oidc_discovery_url  = local.okta_issuer
  oidc_client_id      = okta_app_oauth.default.client_id
  oidc_client_secret  = okta_app_oauth.default.client_secret
  bound_issuer        = local.okta_issuer
  default_role        = "default"
}

resource "vault_jwt_auth_backend_role" "default" {
  backend               = vault_jwt_auth_backend.okta.path
  role_name             = "default"
  role_type             = "oidc"
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "${var.vault_addr}/ui/vault/auth/${local.auth_path}/oidc/callback"
  ]
  user_claim            = "sub"
  groups_claim          = "groups"
  oidc_scopes           = ["profile", "groups", "email"]
  bound_audiences       = [okta_app_oauth.default.client_id]
  token_policies        = [vault_policy.self.name]
 
  claim_mappings = {
    email       = "email"
    name        = "name"
    given_name  = "first_name"
    middle_name = "middle_name"
    family_name = "last_name"
    okta_app_id = "aud"
    issuer      = "iss"
  }
}

resource "vault_policy" "self" {
  name = "self"

  policy = <<EOT
# Allow tokens to query themselves
path "auth/token/lookup-self" {
  capabilities = ["read"]
}

# Allow tokens to renew themselves
path "auth/token/renew-self" {
    capabilities = ["update"]
}

# Allow tokens to revoke themselves
path "auth/token/revoke-self" {
    capabilities = ["update"]
}
EOT
}
