# Implementation Plan

- [ ] 1. Set up Terraform project structure and provider configuration

  - Create directory structure under `infra/terraform/proxmox-k3s/`
  - Write `versions.tf` with Proxmox provider version constraints
  - Configure Proxmox provider in `main.tf` with authentication variables
  - _Requirements: 1.4, 3.4_

- [x] 2. Define input variables and validation

  - Create `variables.tf` with Proxmox connection configuration variables
  - Add VM resource configuration variables (CPU, memory, disk, network)
  - Implement K3s configuration variables with validation rules
  - Add SSH key and network configuration variables
  - _Requirements: 3.1, 3.2, 3.5_

- [x] 3. Create cloud-init configuration template

  - Write `cloud-init.yaml` template for VM initialization
  - Include SSH key injection and user setup
  - Add system update and prerequisite package installation
  - Configure network settings and hostname
  - _Requirements: 2.2, 3.3_

- [x] 4. Implement VM resource definition

  - Create Proxmox VM resource in `main.tf`
  - Configure VM specifications using input variables
  - Set up cloud-init integration with template file
  - Configure network bridge and IP assignment
  - _Requirements: 1.1, 1.2, 1.3_

- [x] 5. Add K3s installation provisioning

  - Extend cloud-init template with K3s installation script
  - Configure K3s server mode with embedded etcd

  - Set up cluster token and node name configuration
  - Add service startup and health check commands
  - _Requirements: 2.1, 2.3, 2.4_

- [x] 6. Implement kubeconfig extraction and outputs

  - Create SSH connection resource for post-deployment access
  - Add provisioner to extract kubeconfig from VM
  - Define output values for VM IP, hostname, and kubeconfig
  - Format kubeconfig for immediate client use
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 7. Add error handling and validation

  - Implement input variable validation with custom conditions
  - Add null_resource for pre-flight checks
  - Create local-exec provisioners for connectivity testing
  - Add depends_on relationships for proper resource ordering
  - _Requirements: 1.5, 2.5, 3.5, 5.4_

- [x] 8. Create example configuration and documentation


  - Write `terraform.tfvars.example` with sample values
  - Create comprehensive `README.md` with usage instructions
  - Document variable descriptions and example values
  - Add troubleshooting section for common issues
  - _Requirements: 3.4, 5.5_

- [ ] 9. Implement resource cleanup and state management

  - Configure proper resource dependencies for clean destruction
  - Add lifecycle rules for critical resources
  - Implement data sources for existing resource validation
  - Create local values for computed configurations
  - _Requirements: 5.1, 5.2, 5.3_

- [ ] 10. Add testing and validation scripts
  - Create validation script to test Proxmox connectivity
  - Write cluster health check script for post-deployment verification
  - Add example deployment script with error handling
  - Implement cleanup verification script
  - _Requirements: 2.4, 4.4, 5.1_
