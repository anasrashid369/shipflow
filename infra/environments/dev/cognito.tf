resource "aws_cognito_user_pool" "main" {
  name = "shipflow-users"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_uppercase = true
    require_symbols   = false
  }

  schema {
    name                = "tenant_id"
    attribute_data_type = "String"
    mutable             = true
    required            = false

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  tags = {
    Name = "shipflow-users"
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "shipflow-app-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  generate_secret = false
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "shipflow-auth"
  user_pool_id = aws_cognito_user_pool.main.id
}