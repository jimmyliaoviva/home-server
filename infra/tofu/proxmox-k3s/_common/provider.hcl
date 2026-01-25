# Provider Configuration
# This file is used by generate "provider" block in root terragrunt.hcl

provider "proxmox" {
  pm_api_url          = var.proxmox_config.endpoint
  pm_api_token_id     = var.proxmox_config.username
  pm_api_token_secret = var.proxmox_config.password
  pm_tls_insecure     = var.proxmox_config.tls_insecure
  pm_timeout          = var.proxmox_config.timeout
}
