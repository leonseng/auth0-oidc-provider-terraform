variable "auth0_domain" {
  type = string
}

variable "auth0_api_token" {
  type      = string
  sensitive = true
}

variable "auth0_user_email" {
  type    = string
  default = "user@example.com"
}

variable "auth0_user_password" {
  type      = string
  sensitive = true
  default   = ""
}

variable "auth0_callback_urls" {
  type = list(string)
}

variable "auth0_allowed_logout_urls" {
  type = list(string)
}
