# Proxmox K3s Terraform Configuration Example
# Copy this file to terraform.tfvars and customize for your environment

# Proxmox connection configuration
proxmox_config = {
  endpoint     = "https://your-proxmox-server:8006/api2/json"  # Proxmox API endpoint
  username     = "terraform@pve"                               # API user (format: user@realm)
  password     = "your-secure-password"                        # API password or token
  node         = "proxmox-node1"                              # Target Proxmox node name
  tls_insecure = true                                         # Skip TLS verification (for self-signed certs)
  timeout      = 300                                          # API timeout in seconds
}

# VM resource configuration
vm_config = {
  name        = "k3s-dev-01"                    # VM name (alphanumeric and hyphens only)
  template    = "ubuntu-22.04-cloud-init"      # Cloud-init enabled template name
  cores       = 2                              # CPU cores (1-32)
  memory      = 4096                           # Memory in MB (512-32768)
  disk_size   = "20G"                          # Disk size with G/M suffix
  storage     = "local-lvm"                    # Proxmox storage pool name
  network     = "vmbr0"                       # Network bridge name
  description = "K3s development cluster"      # VM description (optional)
}

# K3s configuration
k3s_config = {
  version      = "latest"                      # K3s version ("latest" or "v1.28.2+k3s1")
  token        = "your-very-secure-32-character-token-here"  # Cluster token (min 16 chars, recommend 32+)
  node_name    = ""                           # Node name (empty = use VM name)
  disable      = ["traefik"]                  # Components to disable (optional)
  server_args  = "--disable=servicelb"       # Additional server arguments (optional)
  cluster_cidr = "10.42.0.0/16"             # Pod network CIDR
  service_cidr = "10.43.0.0/16"             # Service network CIDR
}

# SSH configuration
ssh_config = {
  public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI... your-key-here"  # Your SSH public key
  username         = "ubuntu"                  # SSH username (default: ubuntu)
  private_key_path = "~/.ssh/id_ed25519"      # Path to private key for provisioning
}

# Network configuration
network_config = {
  ip_address     = "192.168.1.100/24"         # Static IP with CIDR or "dhcp"
  gateway        = "192.168.1.1"              # Network gateway (required for static IP)
  nameserver     = "8.8.8.8"                 # Primary DNS server
  nameserver_2   = "1.1.1.1"                 # Secondary DNS server
  domain         = "local"                     # Network domain
  interface_name = "eth0"                      # Network interface name
}

# System configuration
system_config = {
  timezone = "America/New_York"               # System timezone (Region/City format)
  locale   = "en_US.UTF-8"                   # System locale
}

# Validation and timeout configuration (optional)
validation_config = {
  skip_preflight_checks = false              # Skip pre-deployment validation
  skip_api_validation   = false              # Skip Proxmox API validation
  ssh_timeout          = 600                 # SSH connection timeout (seconds)
  k3s_timeout          = 600                 # K3s installation timeout (seconds)
}

# Example configurations for different scenarios:

# Development Environment (minimal resources)
# vm_config = {
#   name        = "k3s-dev"
#   template    = "ubuntu-22.04-cloud-init"
#   cores       = 2
#   memory      = 2048
#   disk_size   = "15G"
#   storage     = "local-lvm"
#   network     = "vmbr0"
#   description = "K3s development cluster"
# }

# Production Environment (more resources)
# vm_config = {
#   name        = "k3s-prod"
#   template    = "ubuntu-22.04-cloud-init"
#   cores       = 4
#   memory      = 8192
#   disk_size   = "50G"
#   storage     = "ceph-storage"
#   network     = "vmbr1"
#   description = "K3s production cluster"
# }

# DHCP Configuration (automatic IP assignment)
# network_config = {
#   ip_address     = "dhcp"
#   gateway        = ""
#   nameserver     = "8.8.8.8"
#   nameserver_2   = "1.1.1.1"
#   domain         = "local"
#   interface_name = "eth0"
# }

# High-Security Configuration
# k3s_config = {
#   version      = "v1.28.2+k3s1"
#   token        = "super-secure-64-character-token-with-numbers-and-special-chars-123!"
#   node_name    = "secure-k3s-node"
#   disable      = ["traefik", "servicelb", "local-storage"]
#   server_args  = "--disable=servicelb --kube-apiserver-arg=audit-log-maxage=30"
#   cluster_cidr = "172.16.0.0/16"
#   service_cidr = "172.17.0.0/16"
# }