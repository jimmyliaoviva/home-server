# Root Terragrunt Configuration
# This file defines the global configuration for all environments

# Configure Terragrunt to use OpenTofu instead of Terraform
terraform_binary = "tofu"

# Configure version requirements
terraform_version_constraint  = ">= 1.6"
terragrunt_version_constraint = ">= 0.55.0"

# Remote state configuration using PostgreSQL
# Connection string is read from environment variable TF_STATE_CONN_STR
# Set it in your shell: export TF_STATE_CONN_STR="postgres://user:pass@host:port/dbname?sslmode=disable"
remote_state {
  backend = "pg"

  config = {
    conn_str    = get_env("TF_STATE_CONN_STR", "postgres://jimmy:CHANGE_ME@192.168.68.120:5432/tofu_state?sslmode=disable")
    schema_name = replace(path_relative_to_include(), "/", "_")
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Global locals available to all child configurations
locals {
  # Parse environment from directory path
  # Example: environments/dev/single-node → dev
  path_parts  = split("/", path_relative_to_include())
  environment = length(local.path_parts) >= 2 ? local.path_parts[1] : "unknown"
  component   = length(local.path_parts) >= 3 ? local.path_parts[2] : "unknown"
}

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "proxmox" {
      pm_api_url          = var.proxmox_config.endpoint
      pm_api_token_id     = var.proxmox_config.username
      pm_api_token_secret = var.proxmox_config.password
      pm_tls_insecure     = var.proxmox_config.tls_insecure
      pm_timeout          = var.proxmox_config.timeout
    }
  EOF
}

# Note: versions.tf is already defined in modules, so we skip generating it
