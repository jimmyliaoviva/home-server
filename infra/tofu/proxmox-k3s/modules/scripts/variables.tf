variable "vm_config" {
  description = "Virtual machine configuration"
  type = object({
    name = string
  })
}

variable "vm_ip" {
  description = "IP address of the VM"
  type        = string
}

variable "ssh_config" {
  description = "SSH configuration"
  type = object({
    username         = string
    private_key_path = string
  })
}

variable "kubeconfig_ready" {
  description = "Dependency to ensure kubeconfig is ready before creating scripts"
  type        = any
}