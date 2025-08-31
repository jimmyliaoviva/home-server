# Proxmox connection configuration
variable "proxmox_config" {
  type = object({
    endpoint     = string
    username     = string
    password     = string
    node         = string
    tls_insecure = optional(bool, true)
    timeout      = optional(number, 300)
  })
  description = "Proxmox connection configuration including endpoint, credentials, and connection settings"
  
  validation {
    condition     = can(regex("^https?://", var.proxmox_config.endpoint))
    error_message = "Proxmox endpoint must be a valid HTTP or HTTPS URL."
  }
  
  validation {
    condition     = length(var.proxmox_config.username) > 0
    error_message = "Proxmox username cannot be empty."
  }
  
  validation {
    condition     = length(var.proxmox_config.password) > 0
    error_message = "Proxmox password cannot be empty."
  }
  
  validation {
    condition     = length(var.proxmox_config.node) > 0
    error_message = "Proxmox node name cannot be empty."
  }
}

# VM resource configuration
variable "vm_config" {
  type = object({
    name        = string
    template    = string
    cores       = number
    memory      = number
    disk_size   = string
    storage     = string
    network     = string
    description = optional(string, "K3s VM managed by Terraform")
  })
  description = "VM resource configuration including CPU, memory, disk, and network settings"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.vm_config.name))
    error_message = "VM name must contain only alphanumeric characters and hyphens."
  }
  
  validation {
    condition     = var.vm_config.cores >= 1 && var.vm_config.cores <= 32
    error_message = "VM cores must be between 1 and 32."
  }
  
  validation {
    condition     = var.vm_config.memory >= 512 && var.vm_config.memory <= 32768
    error_message = "VM memory must be between 512 MB and 32 GB."
  }
  
  validation {
    condition     = can(regex("^[0-9]+[GM]$", var.vm_config.disk_size))
    error_message = "Disk size must be specified with G (GB) or M (MB) suffix, e.g., '20G' or '1024M'."
  }
  
  validation {
    condition     = length(var.vm_config.template) > 0
    error_message = "VM template name cannot be empty."
  }
  
  validation {
    condition     = length(var.vm_config.storage) > 0
    error_message = "Storage pool name cannot be empty."
  }
  
  validation {
    condition     = length(var.vm_config.network) > 0
    error_message = "Network bridge name cannot be empty."
  }
}

# K3s configuration variables
variable "k3s_config" {
  type = object({
    version     = optional(string, "latest")
    token       = string
    node_name   = optional(string, "")
    disable     = optional(list(string), [])
    server_args = optional(string, "")
    cluster_cidr = optional(string, "10.42.0.0/16")
    service_cidr = optional(string, "10.43.0.0/16")
  })
  description = "K3s installation and configuration settings"
  
  validation {
    condition     = length(var.k3s_config.token) >= 16
    error_message = "K3s token must be at least 16 characters long for security."
  }
  
  validation {
    condition = var.k3s_config.version == "latest" || can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+", var.k3s_config.version))
    error_message = "K3s version must be 'latest' or a valid semantic version like 'v1.28.2+k3s1'."
  }
  
  validation {
    condition = can(cidrhost(var.k3s_config.cluster_cidr, 0))
    error_message = "Cluster CIDR must be a valid CIDR block."
  }
  
  validation {
    condition = can(cidrhost(var.k3s_config.service_cidr, 0))
    error_message = "Service CIDR must be a valid CIDR block."
  }
}

# SSH key and network configuration
variable "ssh_config" {
  type = object({
    public_key  = string
    username    = optional(string, "ubuntu")
    private_key_path = optional(string, "~/.ssh/id_rsa")
  })
  description = "SSH configuration for VM access including public key and user settings"
  
  validation {
    condition     = can(regex("^ssh-(rsa|ed25519|ecdsa)", var.ssh_config.public_key))
    error_message = "SSH public key must be in valid OpenSSH format (ssh-rsa, ssh-ed25519, or ssh-ecdsa)."
  }
  
  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*$", var.ssh_config.username))
    error_message = "SSH username must be a valid Linux username (lowercase, alphanumeric, underscore, hyphen)."
  }
}

# Network configuration
variable "network_config" {
  type = object({
    ip_address     = optional(string, "dhcp")
    gateway        = optional(string, "")
    nameserver     = optional(string, "8.8.8.8")
    nameserver_2   = optional(string, "1.1.1.1")
    domain         = optional(string, "local")
    interface_name = optional(string, "eth0")
  })
  description = "Network configuration for the VM including IP, gateway, and DNS settings"
  
  validation {
    condition = var.network_config.ip_address == "dhcp" || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$", var.network_config.ip_address))
    error_message = "IP address must be 'dhcp' or a valid CIDR notation (e.g., '192.168.1.100/24')."
  }
  
  validation {
    condition = var.network_config.gateway == "" || can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.network_config.gateway))
    error_message = "Gateway must be empty or a valid IP address."
  }
  
  validation {
    condition = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.network_config.nameserver))
    error_message = "Nameserver must be a valid IP address."
  }
  
  validation {
    condition = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", var.network_config.nameserver_2))
    error_message = "Secondary nameserver must be a valid IP address."
  }
}

# System configuration
variable "system_config" {
  type = object({
    timezone = optional(string, "UTC")
    locale   = optional(string, "en_US.UTF-8")
  })
  description = "System configuration including timezone and locale settings"
  
  validation {
    condition = can(regex("^[A-Za-z_]+/[A-Za-z_]+$", var.system_config.timezone)) || var.system_config.timezone == "UTC"
    error_message = "Timezone must be in format 'Region/City' (e.g., 'America/New_York') or 'UTC'."
  }
}

# Additional validation variables for enhanced error checking
variable "validation_config" {
  type = object({
    skip_preflight_checks = optional(bool, false)
    skip_api_validation   = optional(bool, false)
    ssh_timeout          = optional(number, 600)
    k3s_timeout          = optional(number, 600)
  })
  description = "Validation and timeout configuration for deployment process"
  default = {}
  
  validation {
    condition = var.validation_config.ssh_timeout >= 60 && var.validation_config.ssh_timeout <= 3600
    error_message = "SSH timeout must be between 60 and 3600 seconds (1 minute to 1 hour)."
  }
  
  validation {
    condition = var.validation_config.k3s_timeout >= 120 && var.validation_config.k3s_timeout <= 3600
    error_message = "K3s timeout must be between 120 and 3600 seconds (2 minutes to 1 hour)."
  }
}