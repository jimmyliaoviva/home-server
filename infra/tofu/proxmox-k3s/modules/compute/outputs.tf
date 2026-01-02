output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_vm_qemu.k3s_vm.vmid
}

output "vm_ip" {
  description = "The IP address of the VM"
  value       = var.network_config.ip_address != "dhcp" ? split("/", var.network_config.ip_address)[0] : proxmox_vm_qemu.k3s_vm.default_ipv4_address
}

output "vm_name" {
  description = "The name of the VM"
  value       = proxmox_vm_qemu.k3s_vm.name
}

output "ssh_connection" {
  description = "SSH connection string for the VM"
  value       = "ssh -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@${var.network_config.ip_address != "dhcp" ? split("/", var.network_config.ip_address)[0] : proxmox_vm_qemu.k3s_vm.default_ipv4_address}"
}

# output "kubeconfig_path" {
#   description = "Path to the extracted kubeconfig file"
#   value       = "/tmp/${var.vm_config.name}-kubeconfig.yaml"
# }

# output "cluster_endpoint" {
#   description = "K3s cluster API endpoint"
#   value       = "https://${var.network_config.ip_address != "dhcp" ?
#     split("/", var.network_config.ip_address)[0] :
#     proxmox_vm_qemu.k3s_vm.default_ipv4_address}:6443"
# }

# output "cluster_name" {
#   description = "K3s cluster name"
#   value       = var.vm_config.name
# }

# output "vm_ready" {
#   description = "Indicates when VM is ready and accessible"
#   value       = null_resource.wait_for_vm.id
# }

# output "kubeconfig_ready" {
#   description = "Indicates when kubeconfig has been extracted"
#   value       = null_resource.extract_kubeconfig.id
# }