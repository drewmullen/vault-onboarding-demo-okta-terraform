# vault + okta user onboarding with terraform

This repo shows a demo for setting up a common vault onboarding setup. The IDP is Okta which holds users and group memberships. Vault is setup to communicate and retrieve group memerbship info for users from Okta, based on the okta group memberships vault policies are applied to vault users at login via Vault Identity Groups. Below is the pictured design

![architecture](./architecture.png)

## Setup

```shell
cd 1_setup
terraform apply -auto-approve
```

The setup root requires admin auth to Vault and Okta. This creates the necessary resources in Okta: Server Claims, Server Policies (and rules), Scopes, and the Oauth App. In Vault it creates the JWT auth backend (type OIDC) and a single default role for login.


## Onboard and App

Applications are onboarded to app via unique groups in both Okta and Vault. Memberships to those groups determines Vault access for user logins.

```shell
cd ../2_onboard_app
terraform apply -auto-approve
```

By default this root assumes and creates 4 groups for each onboarded app:
- dev read only
- dev read write
- prod read only
- prod read write

This groups are created in Okta then in Vault. A group alias is created for each Vault group as well. Vault matches the group alias to the okta group name to assign policies. Vault policies are also created and assuming the following path

`/{bu}/{lob}/{app id}/{env}/*`

A user who belongs to all 4 groups of the app will have 4 policies (dev-ro, dev-rw, prod-ro, prod-rw).

## Onboard Users

There is a root for onboarding a user for example only (it hasnt been tested). Typically orgs will use an external tool for managing user creation and group access to their IDP.
