terraform {
  required_providers {
    okta = {
        source = "okta/okta"
    }
  }
}

provider "okta" {
  org_name = "integrator-3678783"
  base_url = "okta.com"
}
