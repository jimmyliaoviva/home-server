variable "proxmox_config" {
  description = "Proxmox provider configuration"
  type = object({
    endpoint    = string
    username    = string
    password    = string
    node        = string
    tls_insecure = bool
    timeout     = number
  })
}

variable "vm_config" {
  description = "Virtual machine configuration"
  type = object({
    name        = string
    description = string
    template    = string  # Name of the template to clone from
    cores       = number
    memory      = number
    scsihw      = string
    disk_size   = string
    storage     = string
    network     = string
  })
}

variable "network_config" {
  description = "Network configuration for the VM"
  type = object({
    ip_address     = string
    gateway        = string
    nameserver     = string
    nameserver_2   = string
    domain         = string
    interface_name = string
  })
}

variable "ssh_config" {
  description = "SSH configuration"
  type = object({
    username         = string
    public_key       = string
    private_key_path = string
  })
}

variable "system_config" {
  description = "System configuration"
  type = object({
    timezone = string
    locale   = string
  })
}