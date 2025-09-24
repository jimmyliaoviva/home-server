# Requirements Document

## Introduction

This feature will create Terraform infrastructure code to automate the deployment of a virtual machine in Proxmox and automatically install K3s (lightweight Kubernetes) on it. This will provide a reproducible way to spin up Kubernetes clusters for development and testing purposes within the home server infrastructure.

## Requirements

### Requirement 1

**User Story:** As a DevOps engineer, I want to deploy a VM in Proxmox using Terraform, so that I can have reproducible infrastructure provisioning.

#### Acceptance Criteria

1. WHEN I run `terraform apply` THEN the system SHALL create a new VM in Proxmox with specified configuration
2. WHEN the VM is created THEN the system SHALL assign it appropriate CPU, memory, and disk resources
3. WHEN the VM is provisioned THEN the system SHALL configure network settings with static or DHCP IP assignment
4. IF the Proxmox provider is not configured THEN the system SHALL provide clear error messages about missing credentials
5. WHEN the VM deployment fails THEN the system SHALL provide detailed error information for troubleshooting

### Requirement 2

**User Story:** As a Kubernetes administrator, I want K3s automatically installed on the VM, so that I have a ready-to-use Kubernetes cluster without manual setup.

#### Acceptance Criteria

1. WHEN the VM is successfully created THEN the system SHALL automatically install K3s on the VM
2. WHEN K3s installation begins THEN the system SHALL use cloud-init or SSH provisioning to execute installation commands
3. WHEN K3s is installed THEN the system SHALL configure it with appropriate cluster settings
4. WHEN K3s installation completes THEN the system SHALL verify the cluster is running and accessible
5. IF K3s installation fails THEN the system SHALL provide error logs and rollback options

### Requirement 3

**User Story:** As a system administrator, I want the Terraform configuration to be modular and configurable, so that I can customize VM specifications and K3s settings for different use cases.

#### Acceptance Criteria

1. WHEN I define variables THEN the system SHALL allow customization of VM CPU, memory, disk size, and network settings
2. WHEN I specify K3s options THEN the system SHALL support different K3s installation modes (server, agent, embedded etcd)
3. WHEN I provide SSH keys THEN the system SHALL configure them for secure access to the VM
4. WHEN I set environment-specific values THEN the system SHALL support multiple deployment environments (dev, staging, prod)
5. WHEN configuration is invalid THEN the system SHALL validate inputs and provide helpful error messages

### Requirement 4

**User Story:** As a developer, I want to retrieve the kubeconfig file after deployment, so that I can immediately start using the Kubernetes cluster.

#### Acceptance Criteria

1. WHEN K3s installation completes THEN the system SHALL extract the kubeconfig file from the VM
2. WHEN kubeconfig is retrieved THEN the system SHALL output it as a Terraform output value
3. WHEN the cluster is ready THEN the system SHALL provide connection details including IP address and port
4. WHEN accessing the cluster THEN the system SHALL ensure proper authentication is configured
5. IF kubeconfig retrieval fails THEN the system SHALL provide alternative methods to access the cluster

### Requirement 5

**User Story:** As an infrastructure engineer, I want proper resource cleanup and state management, so that I can safely destroy and recreate the infrastructure when needed.

#### Acceptance Criteria

1. WHEN I run `terraform destroy` THEN the system SHALL cleanly remove the VM from Proxmox
2. WHEN destroying resources THEN the system SHALL handle dependencies and cleanup in proper order
3. WHEN state becomes corrupted THEN the system SHALL provide recovery options
4. WHEN resources are modified outside Terraform THEN the system SHALL detect drift and offer correction
5. WHEN cleanup fails THEN the system SHALL provide manual cleanup instructions