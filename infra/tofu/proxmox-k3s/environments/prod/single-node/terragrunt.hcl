# Production Environment - Single Node Configuration

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Load common defaults
locals {
  common_file = find_in_parent_folders("_common/common.hcl")
  common      = read_terragrunt_config(local.common_file)

  # Proxmox configuration from environment variables
  proxmox_config = {
    endpoint     = get_env("PROXMOX_ENDPOINT")
    username     = get_env("PROXMOX_USERNAME")
    password     = get_env("PROXMOX_PASSWORD")
    node         = get_env("PROXMOX_NODE")
    tls_insecure = get_env("PROXMOX_TLS_INSECURE", "true") == "true"
    timeout      = tonumber(get_env("PROXMOX_TIMEOUT", "300"))
  }

  # SSH configuration from environment variables
  ssh_config = {
    public_key       = get_env("SSH_PUBLIC_KEY")
    username         = get_env("SSH_USERNAME", "jimmy")
    private_key_path = get_env("SSH_PRIVATE_KEY_PATH", "~/.ssh/home_server")
  }

  # Network configuration from environment variables
  network_defaults = {
    gateway        = get_env("NETWORK_GATEWAY", "192.168.68.1")
    nameserver     = get_env("NETWORK_NAMESERVER", "8.8.8.8")
    nameserver_2   = get_env("NETWORK_NAMESERVER_2", "1.1.1.1")
    domain         = get_env("NETWORK_DOMAIN", "local")
    interface_name = get_env("NETWORK_INTERFACE", "eth0")
  }

  # K3s configuration from environment variables
  k3s_defaults = {
    version      = get_env("K3S_VERSION", "v1.28.2+k3s1")
    token        = get_env("K3S_TOKEN", "")
    install_exec = get_env("K3S_INSTALL_EXEC", "")
  }

  # Common defaults
  default_system_config = local.common.locals.default_system_config
  default_k3s_config    = local.common.locals.default_k3s_config
  validation_config     = local.common.locals.validation_config
}

# Point to the compute module using relative path from root
terraform {
  source = "../../../modules/compute"
}

# Component-specific inputs
inputs = {
  # Proxmox configuration
  proxmox_config = local.proxmox_config

  # VM configuration - specific to this deployment
  vm_config = {
    name        = "k3s-prod-01"
    template    = "ubuntu-24.04-cloud-init"
    cores       = 2
    memory      = 4096
    scsihw      = "virtio-scsi-single"
    disk_size   = "20G"
    storage     = "local-lvm"
    network     = "vmbr0"
    description = "K3s production cluster - single node"
  }

  # K3s configuration - merge defaults with component-specific
  k3s_config = merge(
    local.k3s_defaults,
    local.default_k3s_config,
    {
      node_name    = ""
      cluster_cidr = "10.42.0.0/16"
      service_cidr = "10.43.0.0/16"
    }
  )

  # SSH configuration
  ssh_config = local.ssh_config

  # Network configuration - specific IP for this component
  network_config = merge(
    local.network_defaults,
    {
      ip_address = "192.168.68.101/24"
    }
  )

  # System configuration - use common defaults
  system_config = local.default_system_config

  # Validation configuration
  validation_config = local.validation_config
}
