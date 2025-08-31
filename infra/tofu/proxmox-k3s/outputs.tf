# VM resource outputs
output "vm_id" {
  description = "The Proxmox VM ID"
  value       = proxmox_vm_qemu.k3s_vm.vmid
}

output "vm_name" {
  description = "The VM name"
  value       = proxmox_vm_qemu.k3s_vm.name
}

output "vm_ip_address" {
  description = "The VM IP address (static or DHCP assigned)"
  value       = var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address
}

output "vm_hostname" {
  description = "The VM hostname"
  value       = local.hostname
}

output "vm_fqdn" {
  description = "The VM fully qualified domain name"
  value       = "${local.hostname}.${var.network_config.domain}"
}

output "ssh_connection_string" {
  description = "SSH connection string for the VM"
  value       = "ssh ${var.ssh_config.username}@${var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address}"
}

output "vm_specs" {
  description = "VM resource specifications"
  value = {
    cores  = var.vm_config.cores
    memory = var.vm_config.memory
    disk   = var.vm_config.disk_size
    node   = var.proxmox_config.node
  }
}

output "network_config" {
  description = "VM network configuration"
  value = {
    ip_address = var.network_config.ip_address
    gateway    = var.network_config.gateway
    dns        = [var.network_config.nameserver, var.network_config.nameserver_2]
    bridge     = var.vm_config.network
  }
  sensitive = false
}

# K3s cluster outputs
output "k3s_cluster_endpoint" {
  description = "K3s cluster API server endpoint"
  value       = "https://${var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address}:6443"
}

output "k3s_node_name" {
  description = "K3s node name"
  value       = local.k3s_node_name
}

output "k3s_token" {
  description = "K3s cluster token (sensitive)"
  value       = var.k3s_config.token
  sensitive   = true
}

# Kubeconfig outputs
output "kubeconfig_raw" {
  description = "Raw kubeconfig file content for K3s cluster access"
  value       = try(data.local_file.kubeconfig.content, "Kubeconfig not yet available - run terraform refresh after deployment")
  sensitive   = true
}

output "kubeconfig_file_path" {
  description = "Local path to the extracted kubeconfig file"
  value       = "/tmp/${var.vm_config.name}-kubeconfig.yaml"
}

output "kubectl_command" {
  description = "kubectl command to access the cluster"
  value       = "kubectl --kubeconfig=/tmp/${var.vm_config.name}-kubeconfig.yaml"
}

# Connection information
output "cluster_access_info" {
  description = "Complete cluster access information"
  value = {
    cluster_endpoint = "https://${var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address}:6443"
    ssh_command      = "ssh -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@${var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address}"
    kubeconfig_path  = "/tmp/${var.vm_config.name}-kubeconfig.yaml"
    kubectl_command  = "kubectl --kubeconfig=/tmp/${var.vm_config.name}-kubeconfig.yaml"
    node_name        = local.k3s_node_name
  }
  sensitive = false
}

# Deployment status
output "deployment_status" {
  description = "Deployment completion status and next steps"
  value = <<-EOT
    ✅ K3s cluster deployment completed successfully!
    
    📋 Cluster Information:
    • VM Name: ${var.vm_config.name}
    • Node Name: ${local.k3s_node_name}
    • Cluster Endpoint: https://${var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address}:6443
    
    🔑 Access Methods:
    1. SSH Access:
       ssh -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@${var.network_config.ip_address != "dhcp" ? local.static_ip : proxmox_vm_qemu.k3s_vm.default_ipv4_address}
    
    2. Kubectl Access:
       export KUBECONFIG=/tmp/${var.vm_config.name}-kubeconfig.yaml
       kubectl get nodes
    
    3. Alternative kubectl:
       kubectl --kubeconfig=/tmp/${var.vm_config.name}-kubeconfig.yaml get nodes
    
    🚀 Next Steps:
    • Verify cluster: kubectl get nodes
    • Deploy workloads: kubectl apply -f your-app.yaml
    • Access dashboard: kubectl proxy (if dashboard installed)
    
    📁 Kubeconfig saved to: /tmp/${var.vm_config.name}-kubeconfig.yaml
    🛠️  Helper script: /tmp/${var.vm_config.name}-cluster-access.sh
    🔍 Validation script: /tmp/${var.vm_config.name}-validate-kubeconfig.sh
  EOT
}

# Helper script outputs
output "cluster_access_script" {
  description = "Path to the cluster access helper script"
  value       = "/tmp/${var.vm_config.name}-cluster-access.sh"
}

output "kubeconfig_validator_script" {
  description = "Path to the kubeconfig validation script"
  value       = "/tmp/${var.vm_config.name}-validate-kubeconfig.sh"
}