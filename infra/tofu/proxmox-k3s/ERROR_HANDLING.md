# Error Handling and Troubleshooting Guide

This document provides comprehensive guidance for handling errors and troubleshooting issues with the Proxmox K3s Terraform deployment.

## Pre-flight Check Failures

### SSH Key Issues

**Error**: `SSH private key not found`
```bash
❌ ERROR: SSH private key not found at ~/.ssh/id_rsa
```

**Solution**:
1. Generate SSH key pair: `ssh-keygen -t ed25519 -f ~/.ssh/id_rsa`
2. Update `ssh_config.private_key_path` in your terraform.tfvars
3. Ensure the public key is correctly set in `ssh_config.public_key`

**Error**: `Invalid SSH public key format`
```bash
❌ ERROR: Invalid SSH public key format
```

**Solution**:
1. Verify public key format: `ssh-keygen -l -f ~/.ssh/id_rsa.pub`
2. Ensure the public key starts with `ssh-rsa`, `ssh-ed25519`, or `ssh-ecdsa`
3. Copy the entire public key including the key type and comment

### Network Connectivity Issues

**Error**: `Cannot connect to Proxmox`
```bash
❌ ERROR: Cannot connect to Proxmox at proxmox.example.com:8006
```

**Solution**:
1. Verify Proxmox server is running: `ping proxmox.example.com`
2. Check firewall rules allow access to port 8006
3. Verify the endpoint URL in `proxmox_config.endpoint`
4. Test manual connection: `curl -k https://proxmox.example.com:8006/api2/json/version`

## Proxmox API Validation Failures

### Authentication Issues

**Error**: `Proxmox API authentication failed`
```bash
❌ ERROR: Proxmox API authentication failed (HTTP 401)
```

**Solution**:
1. Verify username and password in `proxmox_config`
2. Check if user has API access permissions
3. For API tokens, use format: `username@realm!tokenname`
4. Test authentication manually:
   ```bash
   curl -k -d "username=user@pam&password=pass" \
     -X POST https://proxmox.example.com:8006/api2/json/access/ticket
   ```

### Resource Access Issues

**Error**: `Cannot access Proxmox node`
```bash
❌ ERROR: Cannot access Proxmox node 'pve' (HTTP 403)
```

**Solution**:
1. Verify node name exists: Check Proxmox web interface
2. Ensure user has permissions on the specified node
3. Check user privileges include VM management rights

**Error**: `Cannot access storage`
```bash
❌ ERROR: Cannot access storage 'local-lvm' (HTTP 404)
```

**Solution**:
1. List available storage: Proxmox web interface → Datacenter → Storage
2. Update `vm_config.storage` with correct storage name
3. Ensure storage is enabled and has sufficient space

**Error**: `Template not found`
```bash
❌ ERROR: Template 'ubuntu-22.04-template' not found
```

**Solution**:
1. Verify template exists and is marked as template
2. Check template name matches exactly (case-sensitive)
3. Ensure template is on the specified node
4. Create template if missing:
   ```bash
   # Convert existing VM to template
   qm template <vmid>
   ```

## VM Creation Failures

### Resource Allocation Issues

**Error**: `Insufficient resources`
```bash
ERROR: VM creation failed - insufficient memory/CPU
```

**Solution**:
1. Check available resources on Proxmox node
2. Reduce `vm_config.cores` or `vm_config.memory`
3. Free up resources by stopping other VMs
4. Check storage space availability

### Network Configuration Issues

**Error**: `Network bridge not found`
```bash
ERROR: Network bridge 'vmbr0' does not exist
```

**Solution**:
1. List available bridges: `ip link show type bridge`
2. Update `vm_config.network` with correct bridge name
3. Create bridge if needed in Proxmox network configuration

### Cloud-init Issues

**Error**: `Cloud-init upload failed`
```bash
ERROR: Failed to upload cloud-init configuration
```

**Solution**:
1. Check SSH access to Proxmox host
2. Verify snippets directory exists: `/var/lib/vz/snippets/`
3. Ensure proper permissions on snippets directory
4. Manual upload test:
   ```bash
   scp test-file.yml root@proxmox:/var/lib/vz/snippets/
   ```

## VM Boot and SSH Connection Issues

### VM Boot Problems

**Error**: `VM created but not booting`

**Solution**:
1. Check VM console in Proxmox web interface
2. Verify template is bootable and cloud-init enabled
3. Check EFI/BIOS settings match template requirements
4. Review VM logs: `journalctl -u qemu-server@<vmid>`

### SSH Connection Failures

**Error**: `SSH connection timeout`
```bash
❌ ERROR: Failed to establish SSH connection within 600 seconds
```

**Solution**:
1. Check VM is running and has IP address
2. Verify cloud-init completed successfully
3. Check firewall rules (VM and host)
4. Test manual SSH connection:
   ```bash
   ssh -i ~/.ssh/id_rsa ubuntu@<vm-ip>
   ```

**Error**: `SSH authentication failed`
```bash
❌ ERROR: SSH authentication failed
```

**Solution**:
1. Verify SSH key was injected via cloud-init
2. Check cloud-init logs on VM: `sudo cat /var/log/cloud-init-output.log`
3. Ensure private key matches public key
4. Try password authentication if enabled

### DHCP IP Assignment Issues

**Error**: `Failed to obtain DHCP IP`
```bash
❌ ERROR: Failed to obtain valid DHCP IP after 12 attempts
```

**Solution**:
1. Check DHCP server is running and has available IPs
2. Verify VM network configuration
3. Check network bridge connectivity
4. Use static IP configuration instead:
   ```hcl
   network_config = {
     ip_address = "192.168.1.100/24"
     gateway    = "192.168.1.1"
   }
   ```

## K3s Installation Issues

### Installation Failures

**Error**: `K3s installation failed`
```bash
❌ ERROR: K3s binary not found. Installation may have failed.
```

**Solution**:
1. Check cloud-init logs: `sudo cat /var/log/cloud-init-output.log`
2. Verify internet connectivity from VM
3. Check if installation script downloaded:
   ```bash
   curl -sfL https://get.k3s.io | sh -
   ```
4. Review K3s installation logs: `sudo journalctl -u k3s`

### Service Startup Issues

**Error**: `K3s service not starting`
```bash
❌ ERROR: K3s cluster not ready within 600 seconds
```

**Solution**:
1. Check service status: `sudo systemctl status k3s`
2. Review service logs: `sudo journalctl -u k3s -f`
3. Check system resources (memory, disk space)
4. Verify K3s configuration in cloud-init template
5. Manual service restart: `sudo systemctl restart k3s`

### Cluster Connectivity Issues

**Error**: `kubectl connection failed`
```bash
❌ ERROR: kubectl connectivity failed
```

**Solution**:
1. Verify K3s API server is running: `sudo ss -tlnp | grep 6443`
2. Check kubeconfig file exists: `sudo ls -la /etc/rancher/k3s/k3s.yaml`
3. Test local kubectl: `sudo kubectl get nodes`
4. Check firewall rules for port 6443

## Kubeconfig Extraction Issues

### File Access Problems

**Error**: `Failed to extract kubeconfig`
```bash
❌ ERROR: Failed to extract kubeconfig content
```

**Solution**:
1. Verify SSH connection to VM works
2. Check kubeconfig file exists: `sudo ls -la /etc/rancher/k3s/k3s.yaml`
3. Ensure user has sudo privileges
4. Manual extraction:
   ```bash
   ssh user@vm-ip "sudo cat /etc/rancher/k3s/k3s.yaml" > kubeconfig.yaml
   ```

### External Access Issues

**Error**: `Kubeconfig validation failed`
```bash
⚠️ Kubeconfig validation failed (cluster may not be externally accessible)
```

**Solution**:
1. Check firewall rules allow port 6443
2. Verify VM IP is accessible from client
3. Test direct connection: `telnet <vm-ip> 6443`
4. Consider using kubectl proxy for local access

## Recovery Procedures

### Partial Deployment Recovery

If deployment fails partway through:

1. **Identify the failure point**:
   ```bash
   terraform show
   terraform state list
   ```

2. **Import existing resources** (if VM was created):
   ```bash
   terraform import proxmox_vm_qemu.k3s_vm <node>/<vmid>
   ```

3. **Continue deployment**:
   ```bash
   terraform apply
   ```

### Complete Cleanup and Retry

For complete cleanup and fresh start:

1. **Destroy Terraform resources**:
   ```bash
   terraform destroy
   ```

2. **Clean up temporary files**:
   ```bash
   rm -f /tmp/<vm-name>-*
   ```

3. **Verify VM deletion in Proxmox**

4. **Retry deployment**:
   ```bash
   terraform apply
   ```

### Manual VM Cleanup

If Terraform destroy fails:

1. **Stop VM in Proxmox**:
   ```bash
   qm stop <vmid>
   ```

2. **Delete VM**:
   ```bash
   qm destroy <vmid>
   ```

3. **Clean up cloud-init snippets**:
   ```bash
   rm -f /var/lib/vz/snippets/<vm-name>-user.yml
   ```

4. **Remove from Terraform state**:
   ```bash
   terraform state rm proxmox_vm_qemu.k3s_vm
   ```

## Debugging Commands

### Terraform Debugging
```bash
# Enable detailed logging
export TF_LOG=DEBUG
terraform apply

# Show current state
terraform show

# List resources
terraform state list

# Show specific resource
terraform state show proxmox_vm_qemu.k3s_vm
```

### Proxmox Debugging
```bash
# Check VM status
qm status <vmid>

# View VM configuration
qm config <vmid>

# Check VM logs
journalctl -u qemu-server@<vmid>

# List VMs
qm list
```

### VM Debugging
```bash
# Check cloud-init status
cloud-init status --long

# View cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Check K3s status
sudo systemctl status k3s

# View K3s logs
sudo journalctl -u k3s -f

# Test kubectl locally
sudo kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml
```

## Prevention Best Practices

1. **Always run validation first**:
   ```bash
   ./validate-config.sh
   terraform plan
   ```

2. **Use version constraints** in versions.tf

3. **Test with minimal resources** first

4. **Keep backups** of working configurations

5. **Monitor resource usage** during deployment

6. **Use descriptive naming** for easy identification

7. **Document custom configurations** and modifications

## Getting Help

If issues persist:

1. **Check Terraform logs** with `TF_LOG=DEBUG`
2. **Review Proxmox logs** on the host system
3. **Consult VM console** in Proxmox web interface
4. **Test components individually** (SSH, API, etc.)
5. **Compare with working configurations**

For additional support, provide:
- Terraform version and configuration
- Proxmox version and setup details
- Complete error messages and logs
- Network and infrastructure details