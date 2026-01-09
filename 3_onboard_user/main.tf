data "okta_group" "dev_rw" {
    name = "vault-${var.app_id}-dev-rw"
}

resource "okta_user" "vault_user" {
  login    = "mullen.drew@gmail.com"
  email    = "mullen.drew@gmail.com"
  first_name = "drew"
  last_name = "mullen"
}

resource "okta_group_memberships" "dev_rw" {
  group_id = data.okta_group.dev_rw.id
  users    = [okta_user.vault_user.id]
}

data "okta_user" "admin" {
  login = "drew.mullen@ibm.com"
}

resource "okta_group_memberships" "dev_rw" {
  group_id = data.okta_group.dev_rw.id
  users    = [data.okta_user.admin.id]
}
