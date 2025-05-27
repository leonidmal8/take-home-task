# Add these variables to your variables.tf file
variable "cognito_domain_prefix" {
  description = "Prefix for the Cognito domain (must be globally unique)"
  type        = string
  default     = "your-app-auth"  # Change this to something unique
}

variable "callback_urls" {
  description = "List of callback URLs for Cognito"
  type        = list(string)
  default     = ["https://your-domain.com/oauth2/idpresponse"]  # Update with your actual domain
}

variable "logout_urls" {
  description = "List of logout URLs for Cognito"
  type        = list(string)
  default     = ["https://your-domain.com"]  # Update with your actual domain
}

# Add after your existing resources in main.tf

# Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "${var.app_name}-user-pool"

  # Password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }

  # Username configuration
  username_attributes = ["email"]
  
  # Auto-verified attributes
  auto_verified_attributes = ["email"]

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # User pool add-ons
  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # Schema for additional user attributes
  schema {
    attribute_data_type = "String"
    name               = "email"
    required           = true
    mutable           = true
  }

  tags = {
    Name        = "${var.app_name}-user-pool"
    Environment = var.environment
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.app_name}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # OAuth settings
  generate_secret                      = true
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  
  # Callback and logout URLs
  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Supported identity providers
  supported_identity_providers = ["COGNITO"]

  # Token validity
  access_token_validity  = 60    # 1 hour
  id_token_validity     = 60    # 1 hour 
  refresh_token_validity = 30   # 30 days

  # Token validity units
  token_validity_units {
    access_token  = "minutes"
    id_token     = "minutes"
    refresh_token = "days"
  }

  # Prevent user existence errors
  prevent_user_existence_errors = "ENABLED"

  # Explicit auth flows
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

# Cognito User Pool Domain
resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.main.id
}

# Update the HTTPS Listener to include Cognito authentication
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  # Add authentication action first
  default_action {
    type = "authenticate-cognito"
    order = 1

    authenticate_cognito {
      user_pool_arn       = aws_cognito_user_pool.main.arn
      user_pool_client_id = aws_cognito_user_pool_client.main.id
      user_pool_domain    = aws_cognito_user_pool_domain.main.domain

      # Optional: customize authentication behavior
      authentication_request_extra_params = {
        display = "page"
      }

      # Session settings
      session_cookie_name = "AWSELBAuthSessionCookie"
      session_timeout     = 3600  # 1 hour
      
      # What to do on successful authentication
      on_unauthenticated_request = "authenticate"
    }
  }

  # Forward to target group after authentication
  default_action {
    type             = "forward"
    order           = 2
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# Create a default admin user (optional)
resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.main.id
  username     = "admin"

  attributes = {
    email          = "admin@yourdomain.com"  # Change this
    email_verified = "true"
  }

  # Force user to change password on first login
  message_action = "SUPPRESS"  # Don't send welcome email
  
  # Set temporary password
  temporary_password = "TempPass123!"

  lifecycle {
    ignore_changes = [
      password,
      temporary_password
    ]
  }
}

# Output important values
output "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_user_pool_client_id" {
  description = "ID of the Cognito User Pool Client"
  value       = aws_cognito_user_pool_client.main.id
  sensitive   = true
}

output "cognito_user_pool_domain" {
  description = "Domain of the Cognito User Pool"
  value       = aws_cognito_user_pool_domain.main.domain
}

output "cognito_login_url" {
  description = "Cognito hosted UI login URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.main.id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}
