output "cluster_access_script" {
  description = "Path to the cluster access helper script"
  value       = local_file.cluster_access_script.filename
}

output "kubeconfig_validator_script" {
  description = "Path to the kubeconfig validation script"
  value       = local_file.kubeconfig_validator.filename
}

output "kubeconfig_content" {
  description = "Content of the kubeconfig file"
  value       = data.local_file.kubeconfig.content
  sensitive   = true
}