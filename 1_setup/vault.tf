locals {
  auth_path   = "okta"
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
  user_claim            = "email"
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
