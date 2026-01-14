output "groups" {
  value = {
    "Request access to any of these okta_groups through sailpoint" = {
      for k, v in okta_group.enumeration : v.name => {
        description  = v.description
        vault_policy = vault_policy.enumeration[k].policy
      }
    }
  }
}

output "test" {
  value = "test values"
}