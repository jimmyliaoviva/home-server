# Development Environment - Multi-Node K3s Agent 1 (Worker Node)

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Load environment variables and common defaults
locals {
  # Load environment-specific variables
  env_vars_file = find_in_parent_folders("env-vars.hcl")
  env_vars      = read_terragrunt_config(local.env_vars_file)

  # Load common defaults
  common_file = find_in_parent_folders("_common/common.hcl")
  common      = read_terragrunt_config(local.common_file)

  # Extract configs for easier access
  proxmox_config   = local.env_vars.locals.proxmox_config
  ssh_config       = local.env_vars.locals.ssh_config
  network_defaults = local.env_vars.locals.network_defaults

  # Common defaults
  default_system_config = local.common.locals.default_system_config
}

# Point to the compute module using relative path from root
terraform {
  source = "../../../../modules/compute"
}

# This agent depends on the server being deployed first
dependencies {
  paths = ["../server"]
}

# Component-specific inputs
inputs = {
  # Proxmox configuration
  proxmox_config = local.proxmox_config

  # VM configuration - K3s Agent 1
  vm_config = {
    name        = "k3s-dev-agent-01"
    template    = "ubuntu-24.04-cloud-init"
    cores       = 2
    memory      = 4096
    scsihw      = "virtio-scsi-single"
    disk_size   = "200G"
    storage     = "local-lvm"
    network     = "vmbr0"
    description = "K3s development cluster - agent node 1 (worker)"
  }

  # SSH configuration
  ssh_config = local.ssh_config

  # Network configuration - Agent 1 IP
  network_config = merge(
    local.network_defaults,
    {
      ip_address = "192.168.68.111/24"
    }
  )

  # System configuration - use common defaults (Asia/Taipei)
  system_config = local.default_system_config
}
