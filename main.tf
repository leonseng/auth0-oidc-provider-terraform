
resource "random_id" "id" {
  count       = var.object_name_prefix == "" ? 1 : 0
  byte_length = 4
  prefix      = "auth0-oidc-provider"
}

locals {
  name_prefix = var.object_name_prefix == "" ? random_id.id.dec : var.object_name_prefix
}

resource "auth0_connection" "this" {
  name                 = local.name_prefix
  is_domain_connection = false
  strategy             = "auth0"
  realms               = [local.name_prefix]

  options {
    disable_signup    = false
    requires_username = false
  }
}

resource "auth0_client" "this" {
  name                                = local.name_prefix
  is_first_party                      = true
  app_type                            = "regular_web"
  grant_types                         = ["authorization_code"]
  custom_login_page_on                = false
  is_token_endpoint_ip_header_trusted = false
  oidc_conformant                     = true
  sso_disabled                        = false
  allowed_clients                     = []
  callbacks                           = var.auth0_callback_urls
  allowed_logout_urls                 = var.auth0_allowed_logout_urls

  jwt_configuration {
    alg = "RS256" # cannot be HMAC for client to be OIDC conformant
  }
}

// required for extracting client secret
data "auth0_client" "this" {
  client_id = auth0_client.this.client_id
}

// required for API token to configure user
data "auth0_client" "api_explorer_app" {
  name = "API Explorer Application"
}

resource "auth0_connection_clients" "this" {
  connection_id   = auth0_connection.this.id
  enabled_clients = [data.auth0_client.api_explorer_app.id, auth0_client.this.id]
}

resource "random_password" "this" {
  count = var.auth0_user_password == "" ? 1 : 0

  length = 12
}

locals {
  user_password = var.auth0_user_password == "" ? random_password.this[0].result : var.auth0_user_password
}

resource "auth0_user" "this" {
  depends_on = [auth0_connection_clients.this]

  connection_name = auth0_connection.this.name
  email           = var.auth0_user_email
  password        = local.user_password
}

output "client_id" {
  value = auth0_client.this.client_id
}

output "client_secret" {
  sensitive = true
  value     = data.auth0_client.this.client_secret
}

output "user_email" {
  value = var.auth0_user_email
}

output "user_password" {
  sensitive = true
  value     = local.user_password
}

output "auth0_oidc_config_url" {
  value = "https://${var.auth0_domain}/.well-known/openid-configuration"
}
