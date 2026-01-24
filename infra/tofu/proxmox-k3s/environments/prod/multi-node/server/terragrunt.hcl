# Production Environment - Multi-Node K3s Server (Control Plane)

# Include root configuration
include "root" {
  path = find_in_parent_folders()
}

# Load common defaults
locals {
  common_file = find_in_parent_folders("_common/common.hcl")
  common      = read_terragrunt_config(local.common_file)

  # Proxmox configuration - CLUSTER 1 - from environment variables
  proxmox_config = {
    endpoint     = get_env("PROXMOX_ENDPOINT_CLUSTER1", get_env("PROXMOX_ENDPOINT"))
    username     = get_env("PROXMOX_USERNAME_CLUSTER1", get_env("PROXMOX_USERNAME"))
    password     = get_env("PROXMOX_PASSWORD_CLUSTER1", get_env("PROXMOX_PASSWORD"))
    node         = get_env("PROXMOX_NODE_CLUSTER1", get_env("PROXMOX_NODE"))
    tls_insecure = get_env("PROXMOX_TLS_INSECURE_CLUSTER1", get_env("PROXMOX_TLS_INSECURE", "true")) == "true"
    timeout      = tonumber(get_env("PROXMOX_TIMEOUT_CLUSTER1", get_env("PROXMOX_TIMEOUT", "300")))
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

  # Common defaults
  default_system_config = local.common.locals.default_system_config
}

# Point to the compute module using relative path from root
terraform {
  source = "../../../../modules/compute"
}

# Component-specific inputs
inputs = {
  # Proxmox configuration - CLUSTER 1
  proxmox_config = local.proxmox_config

  # VM configuration - K3s Server (Control Plane)
  vm_config = {
    name        = "k3s-prod-server"
    template    = "ubuntu-24.04-cloud-init"
    cores       = 4              # Production: more resources than dev
    memory      = 8192           # Production: 8GB RAM
    scsihw      = "virtio-scsi-single"
    disk_size   = "200G"
    storage     = "local-lvm"
    network     = "vmbr0"
    description = "K3s production cluster - server node (control plane) - Cluster 1 (n100r)"
  }

  # SSH configuration
  ssh_config = local.ssh_config

  # Network configuration - Server IP
  network_config = merge(
    local.network_defaults,
    {
      ip_address = "192.168.68.210/24"
    }
  )

  # System configuration - use common defaults (Asia/Taipei)
  system_config = local.default_system_config
}
