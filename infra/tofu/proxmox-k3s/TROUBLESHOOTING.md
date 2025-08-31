# Troubleshooting Guide - Proxmox K3s Terraform

This guide provides detailed troubleshooting steps for common issues encountered when deploying K3s clusters on Proxmox using Terraform.

## Quick Diagnostics

### Pre-Deployment Checks
```bash
# Validate configuration
./validate-config.sh

# Check Terraform syntax
terraform validate

# Preview deployment
terraform plan
```

### Post-Deployment Checks
```bash
# Check VM status
ssh ubuntu@<vm-ip> "systemctl status k3s"

# Verify cluster
kubectl --kubeconfig=/tmp/vm-name-kubeconfig.yaml get nodes

# Check logs
ssh ubuntu@<vm-ip> "sudo journalctl -u k3s -f"
```

## Common Issues and Solutions

### 1. Proxmox Connection Issues

#### Issue: "Connection refused" or timeout errors
**Symptoms:**
```
Error: error creating Proxmox client: error connecting to Proxmox API
```

**Diagnosis:**
```bash
# Test basic connectivity
ping your-proxmox-server

# Test API endpoint
curl -k https://your-proxmox-server:8006/api2/json/version

# Check port accessibility
telnet your-proxmox-server 8006
```

**Solutions:**
1. **Verify Proxmox is running:**
   ```bash
   systemctl status pveproxy
   systemctl status pvedaemon
   ```

2. **Check firewall rules:**
   ```bash
   # On Proxmox server
   iptables -L | grep 8006
   
   # Allow API access if needed
   iptables -A INPUT -p tcp --dport 8006 -j ACCEPT
   ```

3. **Verify API service:**
   ```bash
   # Restart Proxmox API services
   systemctl restart pveproxy
   systemctl restart pvedaemon
   ```

#### Issue: Authentication failures
**Symptoms:**
```
Error: 401 Unauthorized
```

**Diagnosis:**
```bash
# Test authentication manually
curl -k -d "username=terraform@pve&password=yourpassword" \
  -X POST https://your-proxmox:8006/api2/json/access/ticket
```

**Solutions:**
1. **Verify user exists and has permissions:**
   ```bash
   # List users
   pveum user list
   
   # Check user permissions
   pveum user permissions terraform@pve
   
   # Add necessary permissions
   pveum role add TerraformRole -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"
   pveum aclmod / -user terraform@pve -role TerraformRole
   ```

2. **Reset user password:**
   ```bash
   pveum passwd terraform@pve
   ```

3. **Use API tokens instead of passwords:**
   ```bash
   # Create API token
   pveum user token add terraform@pve mytoken -privsep 0
   
   # Update terraform.tfvars
   # username = "terraform@pve!mytoken"
   # password = "generated-token-secret"
   ```

### 2. Template and VM Creation Issues

#### Issue: Template not found
**Symptoms:**
```
Error: VM template 'ubuntu-22.04-cloud-init' not found
```

**Diagnosis:**
```bash
# List all VMs and templates
qm list

# Check specific template
qm config <template-id>
```

**Solutions:**
1. **Create cloud-init template:**
   ```bash
   # Download Ubuntu cloud image
   wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
   
   # Create VM
   qm create 9000 --name ubuntu-22.04-cloud-init --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
   
   # Import disk
   qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
   
   # Configure VM
   qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
   qm set 9000 --boot c --bootdisk scsi0
   qm set 9000 --ide2 local-lvm:cloudinit
   qm set 9000 --serial0 socket --vga serial0
   qm set 9000 --agent enabled=1
   
   # Convert to template
   qm template 9000
   ```

2. **Verify template has cloud-init:**
   ```bash
   # Check for cloud-init drive
   qm config 9000 | grep ide2
   
   # Should show: ide2: local-lvm:vm-9000-cloudinit,media=cdrom
   ```

#### Issue: Storage not available
**Symptoms:**
```
Error: storage 'local-lvm' not available on node
```

**Diagnosis:**
```bash
# List available storage
pvesm status

# Check specific storage
pvesm status -storage local-lvm
```

**Solutions:**
1. **Check storage configuration:**
   ```bash
   # View storage config
   cat /etc/pve/storage.cfg
   
   # Check disk space
   df -h
   lvs
   ```

2. **Enable storage for node:**
   ```bash
   # Edit storage config to include nodes
   # In /etc/pve/storage.cfg, ensure 'nodes' includes your target node
   ```

### 3. Network Configuration Issues

#### Issue: VM not getting IP address
**Symptoms:**
- VM boots but no IP assigned
- SSH connection fails
- Network unreachable

**Diagnosis:**
```bash
# Check VM console (Proxmox web interface)
# Look for network interface status

# On VM (via console):
ip addr show
systemctl status networking
```

**Solutions:**
1. **For DHCP issues:**
   ```bash
   # Check DHCP server status
   systemctl status isc-dhcp-server
   
   # Check DHCP leases
   cat /var/lib/dhcp/dhcpd.leases
   
   # Restart networking on VM
   sudo systemctl restart networking
   sudo dhclient eth0
   ```

2. **For static IP issues:**
   ```bash
   # Check cloud-init network config
   sudo cat /etc/netplan/50-cloud-init.yaml
   
   # Apply network config
   sudo netplan apply
   
   # Check routing
   ip route show
   ```

3. **Bridge configuration:**
   ```bash
   # Check bridge status on Proxmox
   ip link show vmbr0
   brctl show vmbr0
   
   # Verify bridge configuration
   cat /etc/network/interfaces
   ```

#### Issue: SSH connection refused
**Symptoms:**
```
ssh: connect to host <ip> port 22: Connection refused
```

**Diagnosis:**
```bash
# Test port connectivity
nc -zv <vm-ip> 22

# Check from VM console
systemctl status ssh
ss -tlnp | grep :22
```

**Solutions:**
1. **SSH service not running:**
   ```bash
   # On VM (via console)
   sudo systemctl start ssh
   sudo systemctl enable ssh
   ```

2. **Firewall blocking SSH:**
   ```bash
   # Check firewall status
   sudo ufw status
   
   # Allow SSH if needed
   sudo ufw allow ssh
   ```

3. **SSH configuration issues:**
   ```bash
   # Check SSH config
   sudo sshd -T | grep -E "(port|listen|permitroot)"
   
   # Test SSH config
   sudo sshd -t
   ```

### 4. SSH Authentication Issues

#### Issue: Permission denied (publickey)
**Symptoms:**
```
Permission denied (publickey)
```

**Diagnosis:**
```bash
# Test SSH with verbose output
ssh -vvv -i ~/.ssh/id_ed25519 ubuntu@<vm-ip>

# Check key format
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```

**Solutions:**
1. **Key permissions:**
   ```bash
   # Fix key permissions
   chmod 600 ~/.ssh/id_ed25519
   chmod 644 ~/.ssh/id_ed25519.pub
   ```

2. **Wrong key format:**
   ```bash
   # Generate new key if needed
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
   
   # Update terraform.tfvars with new public key
   cat ~/.ssh/id_ed25519.pub
   ```

3. **Cloud-init key injection failed:**
   ```bash
   # Check cloud-init logs on VM
   sudo cat /var/log/cloud-init.log | grep -i ssh
   
   # Check authorized_keys
   sudo cat /home/ubuntu/.ssh/authorized_keys
   ```

### 5. Cloud-Init Issues

#### Issue: Cloud-init not running or failing
**Symptoms:**
- User account not created
- SSH keys not installed
- System not configured

**Diagnosis:**
```bash
# Check cloud-init status (on VM via console)
cloud-init status
cloud-init status --long

# Check logs
sudo cat /var/log/cloud-init.log
sudo cat /var/log/cloud-init-output.log
```

**Solutions:**
1. **Cloud-init not installed in template:**
   ```bash
   # Install cloud-init in template
   sudo apt update
   sudo apt install cloud-init
   
   # Enable cloud-init services
   sudo systemctl enable cloud-init
   sudo systemctl enable cloud-init-local
   sudo systemctl enable cloud-config
   sudo systemctl enable cloud-final
   ```

2. **Cloud-init configuration errors:**
   ```bash
   # Check cloud-init config
   sudo cloud-init schema --system
   
   # Re-run cloud-init (if safe)
   sudo cloud-init clean
   sudo cloud-init init
   ```

3. **Template preparation issues:**
   ```bash
   # Clean template before converting
   sudo cloud-init clean --logs
   sudo rm -rf /var/lib/cloud/
   sudo rm -rf /etc/machine-id
   sudo truncate -s 0 /etc/hostname
   ```

### 6. K3s Installation Issues

#### Issue: K3s installation fails
**Symptoms:**
```
Error: K3s installation script failed
```

**Diagnosis:**
```bash
# Check K3s installation logs
ssh ubuntu@<vm-ip> "sudo journalctl -u k3s -n 50"

# Check if K3s binary exists
ssh ubuntu@<vm-ip> "which k3s"

# Check system requirements
ssh ubuntu@<vm-ip> "free -h && df -h"
```

**Solutions:**
1. **Network connectivity issues:**
   ```bash
   # Test internet connectivity from VM
   ssh ubuntu@<vm-ip> "curl -I https://get.k3s.io"
   
   # Check DNS resolution
   ssh ubuntu@<vm-ip> "nslookup get.k3s.io"
   ```

2. **Insufficient resources:**
   ```bash
   # Check memory and disk space
   ssh ubuntu@<vm-ip> "free -h"
   ssh ubuntu@<vm-ip> "df -h"
   
   # Increase VM resources if needed
   qm set <vmid> --memory 4096
   qm set <vmid> --cores 2
   ```

3. **Manual K3s installation:**
   ```bash
   # Install K3s manually
   ssh ubuntu@<vm-ip>
   curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.28.2+k3s1" sh -s - server \
     --token "your-token" \
     --cluster-cidr "10.42.0.0/16" \
     --service-cidr "10.43.0.0/16"
   ```

#### Issue: K3s service not starting
**Symptoms:**
```
k3s.service failed to start
```

**Diagnosis:**
```bash
# Check service status
ssh ubuntu@<vm-ip> "sudo systemctl status k3s"

# Check logs
ssh ubuntu@<vm-ip> "sudo journalctl -u k3s -f"

# Check configuration
ssh ubuntu@<vm-ip> "sudo cat /etc/systemd/system/k3s.service"
```

**Solutions:**
1. **Port conflicts:**
   ```bash
   # Check if ports are in use
   ssh ubuntu@<vm-ip> "sudo ss -tlnp | grep -E ':(6443|10250)'"
   
   # Kill conflicting processes if needed
   ssh ubuntu@<vm-ip> "sudo pkill -f k3s"
   ```

2. **Configuration errors:**
   ```bash
   # Check K3s config
   ssh ubuntu@<vm-ip> "sudo cat /etc/rancher/k3s/k3s.yaml"
   
   # Restart with debug logging
   ssh ubuntu@<vm-ip> "sudo k3s server --debug"
   ```

### 7. Kubeconfig Issues

#### Issue: Cannot extract kubeconfig
**Symptoms:**
```
Error: Failed to retrieve kubeconfig
```

**Diagnosis:**
```bash
# Check if kubeconfig exists on VM
ssh ubuntu@<vm-ip> "sudo ls -la /etc/rancher/k3s/k3s.yaml"

# Check file permissions
ssh ubuntu@<vm-ip> "sudo cat /etc/rancher/k3s/k3s.yaml"
```

**Solutions:**
1. **File permissions:**
   ```bash
   # Fix kubeconfig permissions
   ssh ubuntu@<vm-ip> "sudo chmod 644 /etc/rancher/k3s/k3s.yaml"
   ```

2. **Manual kubeconfig extraction:**
   ```bash
   # Copy kubeconfig manually
   scp -i ~/.ssh/id_ed25519 ubuntu@<vm-ip>:/etc/rancher/k3s/k3s.yaml ./kubeconfig.yaml
   
   # Update server address
   sed -i 's/127.0.0.1/<vm-ip>/' kubeconfig.yaml
   
   # Test connection
   kubectl --kubeconfig=./kubeconfig.yaml get nodes
   ```

#### Issue: kubectl connection refused
**Symptoms:**
```
Unable to connect to the server: dial tcp <ip>:6443: connect: connection refused
```

**Diagnosis:**
```bash
# Check if API server is running
ssh ubuntu@<vm-ip> "sudo ss -tlnp | grep 6443"

# Check K3s process
ssh ubuntu@<vm-ip> "ps aux | grep k3s"
```

**Solutions:**
1. **API server not ready:**
   ```bash
   # Wait for API server to start
   ssh ubuntu@<vm-ip> "sudo systemctl restart k3s"
   
   # Monitor startup
   ssh ubuntu@<vm-ip> "sudo journalctl -u k3s -f"
   ```

2. **Firewall blocking API port:**
   ```bash
   # Check firewall
   ssh ubuntu@<vm-ip> "sudo ufw status"
   
   # Allow API port
   ssh ubuntu@<vm-ip> "sudo ufw allow 6443"
   ```

## Advanced Troubleshooting

### Debug Mode Deployment
```bash
# Enable Terraform debug logging
export TF_LOG=DEBUG
terraform apply

# Enable verbose SSH
ssh -vvv -i ~/.ssh/id_ed25519 ubuntu@<vm-ip>
```

### Manual Deployment Steps
If automated deployment fails, try manual steps:

1. **Create VM manually:**
   ```bash
   qm clone 9000 101 --name test-k3s --full
   qm set 101 --memory 4096 --cores 2
   qm start 101
   ```

2. **Configure networking:**
   ```bash
   # Set static IP via Proxmox
   qm set 101 --ipconfig0 ip=192.168.1.100/24,gw=192.168.1.1
   ```

3. **Install K3s manually:**
   ```bash
   ssh ubuntu@192.168.1.100
   curl -sfL https://get.k3s.io | sh -
   ```

### Log Collection
Collect logs for support:

```bash
# Terraform logs
terraform apply 2>&1 | tee terraform.log

# System logs from VM
ssh ubuntu@<vm-ip> "sudo journalctl --since '1 hour ago' > /tmp/system.log"
scp ubuntu@<vm-ip>:/tmp/system.log ./

# K3s logs
ssh ubuntu@<vm-ip> "sudo journalctl -u k3s --since '1 hour ago' > /tmp/k3s.log"
scp ubuntu@<vm-ip>:/tmp/k3s.log ./

# Cloud-init logs
ssh ubuntu@<vm-ip> "sudo cat /var/log/cloud-init.log > /tmp/cloud-init.log"
scp ubuntu@<vm-ip>:/tmp/cloud-init.log ./
```

### Recovery Procedures

#### Partial Deployment Recovery
```bash
# Import existing VM into Terraform state
terraform import proxmox_vm_qemu.k3s_vm <node>/<vmid>

# Refresh state
terraform refresh

# Continue deployment
terraform apply
```

#### Complete Cleanup
```bash
# Destroy Terraform resources
terraform destroy

# Clean up local files
rm -f /tmp/*kubeconfig*
rm -f /tmp/*cluster-access*

# Manual VM cleanup (if needed)
qm stop <vmid>
qm destroy <vmid>
```

## Prevention Tips

1. **Always validate configuration:**
   ```bash
   ./validate-config.sh
   terraform validate
   terraform plan
   ```

2. **Test in development first:**
   - Use minimal resources for testing
   - Validate network connectivity
   - Test SSH access manually

3. **Monitor deployment:**
   - Watch Terraform output carefully
   - Check VM console during deployment
   - Monitor system resources

4. **Keep backups:**
   - Backup working configurations
   - Document custom modifications
   - Save working kubeconfig files

5. **Regular maintenance:**
   - Update templates regularly
   - Keep Terraform providers updated
   - Monitor Proxmox logs

## Getting Help

If issues persist:

1. **Check documentation:**
   - Terraform Proxmox provider docs
   - K3s documentation
   - Proxmox VE documentation

2. **Community resources:**
   - Proxmox community forum
   - K3s GitHub issues
   - Terraform community

3. **Collect information:**
   - Terraform version: `terraform version`
   - Proxmox version: `pveversion`
   - Error messages and logs
   - Configuration files (sanitized)

Remember to sanitize sensitive information (passwords, tokens, IP addresses) before sharing logs or configurations.