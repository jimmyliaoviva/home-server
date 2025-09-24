# Proxmox K3s OpenTofu/Terraform Module

This OpenTofu/Terraform module automates the deployment of virtual machines in Proxmox and automatically installs K3s (lightweight Kubernetes) using cloud-init. It provides a complete infrastructure-as-code solution for spinning up ready-to-use Kubernetes clusters in your Proxmox environment.

**Compatible with both OpenTofu and Terraform** - Use your preferred tool!

## Features

- 🚀 **Automated VM Provisioning**: Creates VMs in Proxmox with customizable specifications
- 🔧 **Cloud-Init Integration**: Automated system configuration and K3s installation
- 🔐 **Security Focused**: SSH key authentication, secure defaults, input validation
- 🌐 **Flexible Networking**: Support for both static IP and DHCP configuration
- 📊 **Comprehensive Validation**: Pre-flight checks and error handling
- 🎯 **Production Ready**: Configurable for development, staging, and production environments
- 📋 **Complete Outputs**: Kubeconfig extraction and cluster access information

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit the configuration** with your Proxmox and environment details:
   ```bash
   nano terraform.tfvars
   ```

3. **Initialize and deploy:**
   
   **Using OpenTofu (recommended):**
   ```bash
   tofu init
   tofu plan
   tofu apply
   ```
   
   **Using Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Access your cluster:**
   ```bash
   export KUBECONFIG=/tmp/your-vm-name-kubeconfig.yaml
   kubectl get nodes
   ```

## Prerequisites

### Proxmox Environment
- **Proxmox VE 7.0+** with API access enabled
- **Cloud-init enabled VM template** (Ubuntu 22.04 LTS recommended)
- **Network bridge** configured (typically `vmbr0`)
- **Storage pool** available (local-lvm, ceph, etc.)

### Local Requirements
- **OpenTofu 1.6+** or **Terraform 1.0+**
- **SSH client** with key pair generated
- **Network connectivity** to Proxmox server
- **curl** (optional, for API validation)

### Tool Installation
**OpenTofu (recommended):**
```bash
# Install OpenTofu (example for Linux)
curl -fsSL https://get.opentofu.org/install-opentofu.sh | sh

# Or using package managers:
# Ubuntu/Debian: apt install tofu
# macOS: brew install opentofu
# Windows: choco install opentofu
```

**Terraform:**
```bash
# Install Terraform (example for Linux)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### Proxmox Template Setup
Create a cloud-init enabled template:
```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM and convert to template
qm create 9000 --name ubuntu-22.04-cloud-init --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

## Configuration

### Required Variables

#### Proxmox Configuration
```hcl
proxmox_config = {
  endpoint     = "https://your-proxmox:8006/api2/json"  # Proxmox API URL
  username     = "terraform@pve"                        # API user
  password     = "your-password"                        # API password
  node         = "proxmox-node1"                       # Target node
  tls_insecure = true                                  # Skip TLS verification
  timeout      = 300                                   # API timeout (seconds)
}
```

#### VM Configuration
```hcl
vm_config = {
  name        = "k3s-cluster-01"           # VM name (alphanumeric + hyphens)
  template    = "ubuntu-22.04-cloud-init" # Template name
  cores       = 2                         # CPU cores (1-32)
  memory      = 4096                      # Memory in MB (512-32768)
  disk_size   = "20G"                     # Disk size (format: "20G" or "2048M")
  storage     = "local-lvm"               # Storage pool
  network     = "vmbr0"                   # Network bridge
  description = "K3s cluster"             # Description (optional)
}
```

#### K3s Configuration
```hcl
k3s_config = {
  version      = "latest"                              # K3s version
  token        = "your-secure-32-character-token"     # Cluster token (min 16 chars)
  node_name    = ""                                   # Node name (empty = VM name)
  disable      = ["traefik"]                          # Disable components
  server_args  = "--disable=servicelb"               # Additional arguments
  cluster_cidr = "10.42.0.0/16"                      # Pod network CIDR
  service_cidr = "10.43.0.0/16"                      # Service network CIDR
}
```

#### SSH Configuration
```hcl
ssh_config = {
  public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5..."  # SSH public key
  username         = "ubuntu"                                # SSH username
  private_key_path = "~/.ssh/id_ed25519"                    # Private key path
}
```

#### Network Configuration
```hcl
network_config = {
  ip_address     = "192.168.1.100/24"  # Static IP with CIDR or "dhcp"
  gateway        = "192.168.1.1"       # Gateway (required for static)
  nameserver     = "8.8.8.8"          # Primary DNS
  nameserver_2   = "1.1.1.1"          # Secondary DNS
  domain         = "local"             # Domain name
  interface_name = "eth0"              # Interface name
}
```

### Optional Variables

#### System Configuration
```hcl
system_config = {
  timezone = "America/New_York"  # Timezone (Region/City format)
  locale   = "en_US.UTF-8"      # System locale
}
```

#### Validation Configuration
```hcl
validation_config = {
  skip_preflight_checks = false  # Skip pre-deployment checks
  skip_api_validation   = false  # Skip API validation
  ssh_timeout          = 600    # SSH timeout (60-3600 seconds)
  k3s_timeout          = 600    # K3s timeout (120-3600 seconds)
}
```

## Variable Validation

The module includes comprehensive input validation:

### Proxmox Config Validation
- ✅ Endpoint must be valid HTTP/HTTPS URL
- ✅ Username and password cannot be empty
- ✅ Node name cannot be empty

### VM Config Validation
- ✅ VM name: alphanumeric characters and hyphens only
- ✅ CPU cores: 1-32 range
- ✅ Memory: 512MB-32GB range
- ✅ Disk size: must include G/M suffix (e.g., "20G", "1024M")
- ✅ Template and storage names cannot be empty

### K3s Config Validation
- ✅ Token: minimum 16 characters (32+ recommended)
- ✅ Version: "latest" or semantic version format
- ✅ CIDR blocks: valid CIDR notation

### SSH Config Validation
- ✅ Public key: valid OpenSSH format
- ✅ Username: valid Linux username format

### Network Config Validation
- ✅ IP address: "dhcp" or valid CIDR notation
- ✅ Gateway: valid IP address format
- ✅ DNS servers: valid IP address format

## Outputs

After successful deployment, the module provides:

### VM Information
- `vm_id`: Proxmox VM ID
- `vm_name`: VM name
- `vm_ip_address`: IP address (static or DHCP assigned)
- `vm_hostname`: VM hostname
- `vm_fqdn`: Fully qualified domain name
- `ssh_connection_string`: SSH command for VM access

### K3s Cluster Information
- `k3s_cluster_endpoint`: Kubernetes API server URL
- `k3s_node_name`: K3s node name
- `k3s_token`: Cluster token (sensitive)

### Kubeconfig Access
- `kubeconfig_raw`: Raw kubeconfig content (sensitive)
- `kubeconfig_file_path`: Local kubeconfig file path
- `kubectl_command`: kubectl command with kubeconfig
- `cluster_access_info`: Complete access information

### Helper Scripts
- `cluster_access_script`: Cluster access helper script
- `kubeconfig_validator_script`: Kubeconfig validation script

## Usage Examples

### Development Environment
```hcl
vm_config = {
  name      = "k3s-dev"
  template  = "ubuntu-22.04-cloud-init"
  cores     = 2
  memory    = 2048
  disk_size = "15G"
  storage   = "local-lvm"
  network   = "vmbr0"
}

k3s_config = {
  version = "latest"
  token   = "dev-cluster-token-12345678"
  disable = ["traefik", "servicelb"]
}
```

### Production Environment
```hcl
vm_config = {
  name      = "k3s-prod"
  template  = "ubuntu-22.04-cloud-init"
  cores     = 4
  memory    = 8192
  disk_size = "50G"
  storage   = "ceph-storage"
  network   = "vmbr1"
}

k3s_config = {
  version      = "v1.28.2+k3s1"
  token        = "production-secure-token-with-64-characters-for-maximum-security"
  server_args  = "--kube-apiserver-arg=audit-log-maxage=30"
  cluster_cidr = "172.16.0.0/16"
  service_cidr = "172.17.0.0/16"
}
```

### DHCP Configuration
```hcl
network_config = {
  ip_address     = "dhcp"
  gateway        = ""
  nameserver     = "8.8.8.8"
  nameserver_2   = "1.1.1.1"
  domain         = "local"
  interface_name = "eth0"
}
```

## Deployment Process

The module follows this deployment sequence:

1. **Pre-flight Checks** 🔍
   - Validates required tools (SSH, SCP)
   - Checks SSH key permissions
   - Tests network connectivity to Proxmox
   - Validates CIDR block configuration

2. **Cross-Variable Validation** ✅
   - Checks configuration consistency
   - Validates VM name against reserved names
   - Verifies K3s version format
   - Warns about potential network conflicts

3. **Proxmox API Validation** 🔐
   - Tests API authentication
   - Verifies node accessibility
   - Checks storage availability
   - Confirms template existence

4. **VM Creation** 🖥️
   - Creates VM with specified configuration
   - Uploads cloud-init configuration
   - Starts VM and waits for boot

5. **System Initialization** ⚙️
   - Waits for SSH connectivity
   - Monitors cloud-init completion
   - Validates system readiness

6. **K3s Installation** 🚀
   - Downloads and installs K3s
   - Configures cluster settings
   - Starts K3s services
   - Validates cluster health

7. **Kubeconfig Extraction** 📋
   - Retrieves kubeconfig from VM
   - Formats for local use
   - Creates helper scripts
   - Validates cluster access

## Post-Deployment

After successful deployment:

### Immediate Access
```bash
# SSH to the VM
ssh -i ~/.ssh/id_ed25519 ubuntu@<vm-ip>

# Use kubectl with extracted kubeconfig
export KUBECONFIG=/tmp/your-vm-name-kubeconfig.yaml
kubectl get nodes

# Alternative kubectl usage
kubectl --kubeconfig=/tmp/your-vm-name-kubeconfig.yaml get nodes
```

### Cluster Validation
```bash
# Check cluster status
kubectl get nodes -o wide
kubectl get pods -A

# Verify K3s services
kubectl get svc -A

# Check cluster info
kubectl cluster-info
```

### Helper Scripts
The module creates several helper scripts:

1. **Cluster Access Script** (`/tmp/vm-name-cluster-access.sh`)
   - Sets up environment variables
   - Provides common kubectl commands

2. **Kubeconfig Validator** (`/tmp/vm-name-validate-kubeconfig.sh`)
   - Validates kubeconfig connectivity
   - Tests cluster access

## Troubleshooting

### Common Issues

#### 1. Proxmox Connection Issues
**Symptoms:**
- "Connection refused" errors
- API authentication failures
- Timeout errors

**Solutions:**
```bash
# Test Proxmox connectivity
curl -k https://your-proxmox:8006/api2/json/version

# Check API user permissions
pveum user list

# Verify node name
pvesh get /nodes
```

#### 2. Template Issues
**Symptoms:**
- "Template not found" errors
- VM creation failures
- Cloud-init not working

**Solutions:**
```bash
# List available templates
qm list | grep template

# Check template cloud-init support
qm config <template-id>

# Verify template has cloud-init drive
qm config <template-id> | grep ide2
```

#### 3. Network Configuration Issues
**Symptoms:**
- VM not getting IP address
- SSH connection failures
- Network unreachable errors

**Solutions:**
```bash
# Check network bridges
ip link show type bridge

# Verify DHCP server (if using DHCP)
systemctl status isc-dhcp-server

# Test static IP configuration
ping <static-ip>
```

#### 4. SSH Connection Issues
**Symptoms:**
- "Permission denied" errors
- "Connection refused" errors
- Key authentication failures

**Solutions:**
```bash
# Check SSH key permissions
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Verify SSH key format
ssh-keygen -l -f ~/.ssh/id_ed25519.pub

# Test SSH connection manually
ssh -v -i ~/.ssh/id_ed25519 ubuntu@<vm-ip>
```

#### 5. K3s Installation Issues
**Symptoms:**
- K3s service not starting
- Cluster not accessible
- Kubeconfig extraction failures

**Solutions:**
```bash
# Check K3s service status on VM
ssh ubuntu@<vm-ip> "sudo systemctl status k3s"

# View K3s logs
ssh ubuntu@<vm-ip> "sudo journalctl -u k3s -f"

# Manually restart K3s
ssh ubuntu@<vm-ip> "sudo systemctl restart k3s"
```

#### 6. Cloud-Init Issues
**Symptoms:**
- VM not configuring properly
- User account not created
- Network not configured

**Solutions:**
```bash
# Check cloud-init status on VM
ssh ubuntu@<vm-ip> "cloud-init status"

# View cloud-init logs
ssh ubuntu@<vm-ip> "sudo cat /var/log/cloud-init.log"

# Re-run cloud-init (if needed)
ssh ubuntu@<vm-ip> "sudo cloud-init clean && sudo cloud-init init"
```

### Validation Commands

#### Pre-Deployment Validation
```bash
# Validate Terraform configuration
terraform validate

# Check Terraform plan
terraform plan

# Validate SSH key
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```

#### Post-Deployment Validation
```bash
# Test cluster connectivity
kubectl --kubeconfig=/tmp/vm-name-kubeconfig.yaml get nodes

# Verify all pods are running
kubectl --kubeconfig=/tmp/vm-name-kubeconfig.yaml get pods -A

# Check cluster resources
kubectl --kubeconfig=/tmp/vm-name-kubeconfig.yaml top nodes
```

### Debug Mode

Enable verbose logging for troubleshooting:

```bash
# Terraform debug mode
export TF_LOG=DEBUG
terraform apply

# SSH debug mode
ssh -vvv -i ~/.ssh/id_ed25519 ubuntu@<vm-ip>
```

### Recovery Procedures

#### Partial Deployment Failure
```bash
# Check Terraform state
terraform show

# Refresh state
terraform refresh

# Targeted apply for specific resources
terraform apply -target=proxmox_vm_qemu.k3s_vm
```

#### Complete Cleanup
```bash
# Destroy all resources
terraform destroy

# Clean local files
rm -f /tmp/vm-name-*

# Reset Terraform state (if needed)
terraform state list
terraform state rm <resource-name>
```

## Security Considerations

### SSH Security
- Use Ed25519 keys for better security
- Disable password authentication
- Use non-standard SSH ports if needed
- Implement SSH key rotation

### Network Security
- Use private IP ranges
- Configure firewall rules
- Implement network segmentation
- Monitor network traffic

### K3s Security
- Use strong cluster tokens (32+ characters)
- Enable audit logging
- Implement RBAC policies
- Regular security updates

### Proxmox Security
- Use dedicated API users
- Implement least-privilege access
- Enable two-factor authentication
- Regular backup of configurations

## Performance Tuning

### VM Resources
- **Development**: 2 CPU, 2-4GB RAM, 15-20GB disk
- **Testing**: 2-4 CPU, 4-8GB RAM, 20-30GB disk
- **Production**: 4+ CPU, 8+ GB RAM, 50+ GB disk

### K3s Optimization
```hcl
k3s_config = {
  server_args = "--kube-apiserver-arg=max-requests-inflight=400 --kube-controller-manager-arg=node-monitor-grace-period=16s"
}
```

### Network Performance
- Use virtio network drivers
- Configure appropriate MTU sizes
- Use dedicated network bridges for production

## Advanced Configuration

### Custom Cloud-Init
Modify `cloud-init.tpl` for custom configurations:
- Additional software installation
- Custom user configurations
- Security hardening scripts
- Monitoring agent installation

### Multi-Node Clusters
For multi-node clusters, deploy multiple VMs and join them:
```bash
# On additional nodes
curl -sfL https://get.k3s.io | K3S_URL=https://<master-ip>:6443 K3S_TOKEN=<token> sh -
```

### Integration with CI/CD
Use in automated pipelines:
```yaml
# GitHub Actions example
- name: Deploy K3s Cluster
  run: |
    terraform init
    terraform apply -auto-approve
    export KUBECONFIG=/tmp/cluster-kubeconfig.yaml
    kubectl apply -f manifests/
```

## Contributing

To contribute to this module:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## License

This module is released under the MIT License. See LICENSE file for details.

## Support

For support and questions:
- Check the troubleshooting section above
- Review Terraform and Proxmox documentation
- Open an issue in the repository
- Consult the K3s documentation

---

**Note**: This module is designed for infrastructure automation. Always test in a development environment before deploying to production.