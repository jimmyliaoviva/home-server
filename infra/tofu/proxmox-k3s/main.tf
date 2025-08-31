# Proxmox Provider Configuration
provider "proxmox" {
  pm_api_url      = var.proxmox_config.endpoint
  pm_user         = var.proxmox_config.username
  pm_password     = var.proxmox_config.password
  pm_tls_insecure = var.proxmox_config.tls_insecure
  pm_timeout      = var.proxmox_config.timeout
}

# Pre-flight checks and validation
resource "null_resource" "preflight_checks" {
  # Validate Proxmox connectivity and prerequisites
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 Running pre-flight checks..."
      
      # Check if required tools are available
      echo "Checking required tools..."
      
      # Check for SSH client
      if ! command -v ssh >/dev/null 2>&1; then
        echo "❌ ERROR: ssh client not found. Please install OpenSSH client."
        exit 1
      fi
      echo "✅ SSH client found"
      
      # Check for SCP (usually comes with SSH)
      if ! command -v scp >/dev/null 2>&1; then
        echo "❌ ERROR: scp not found. Please install OpenSSH client with scp support."
        exit 1
      fi
      echo "✅ SCP found"
      
      # Check if private key file exists and has correct permissions
      if [ ! -f "${var.ssh_config.private_key_path}" ]; then
        echo "❌ ERROR: SSH private key not found at ${var.ssh_config.private_key_path}"
        echo "   Please ensure the private key exists and is accessible."
        exit 1
      fi
      echo "✅ SSH private key found"
      
      # Check private key permissions (should be 600 or 400)
      key_perms=$(stat -c "%a" "${var.ssh_config.private_key_path}" 2>/dev/null || stat -f "%A" "${var.ssh_config.private_key_path}" 2>/dev/null || echo "unknown")
      if [ "$key_perms" != "600" ] && [ "$key_perms" != "400" ]; then
        echo "⚠️  WARNING: SSH private key permissions are $key_perms, should be 600 or 400"
        echo "   Consider running: chmod 600 ${var.ssh_config.private_key_path}"
      else
        echo "✅ SSH private key permissions are secure"
      fi
      
      # Validate SSH public key format
      if ! echo "${var.ssh_config.public_key}" | ssh-keygen -l -f - >/dev/null 2>&1; then
        echo "❌ ERROR: Invalid SSH public key format"
        echo "   Please provide a valid OpenSSH public key"
        exit 1
      fi
      echo "✅ SSH public key format is valid"
      
      # Check network connectivity to Proxmox endpoint
      echo "Testing Proxmox connectivity..."
      proxmox_host=$(echo "${var.proxmox_config.endpoint}" | sed 's|https\?://||' | sed 's|/.*||' | sed 's|:.*||')
      proxmox_port=$(echo "${var.proxmox_config.endpoint}" | grep -o ':[0-9]*' | sed 's/://' || echo "8006")
      
      if command -v nc >/dev/null 2>&1; then
        if ! nc -z -w5 "$proxmox_host" "$proxmox_port" 2>/dev/null; then
          echo "❌ ERROR: Cannot connect to Proxmox at $proxmox_host:$proxmox_port"
          echo "   Please check network connectivity and Proxmox server status"
          exit 1
        fi
        echo "✅ Network connectivity to Proxmox confirmed"
      elif command -v telnet >/dev/null 2>&1; then
        if ! timeout 5 telnet "$proxmox_host" "$proxmox_port" </dev/null >/dev/null 2>&1; then
          echo "❌ ERROR: Cannot connect to Proxmox at $proxmox_host:$proxmox_port"
          echo "   Please check network connectivity and Proxmox server status"
          exit 1
        fi
        echo "✅ Network connectivity to Proxmox confirmed"
      else
        echo "⚠️  WARNING: Cannot test network connectivity (nc or telnet not available)"
        echo "   Proceeding without network connectivity test"
      fi
      
      # Validate CIDR blocks don't overlap
      cluster_cidr="${var.k3s_config.cluster_cidr}"
      service_cidr="${var.k3s_config.service_cidr}"
      
      # Extract network portions for basic overlap check
      cluster_net=$(echo "$cluster_cidr" | cut -d'/' -f1 | cut -d'.' -f1-2)
      service_net=$(echo "$service_cidr" | cut -d'/' -f1 | cut -d'.' -f1-2)
      
      if [ "$cluster_net" = "$service_net" ]; then
        echo "⚠️  WARNING: Cluster CIDR ($cluster_cidr) and Service CIDR ($service_cidr) may overlap"
        echo "   This could cause networking issues in the K3s cluster"
      else
        echo "✅ Cluster and Service CIDR blocks appear to be separate"
      fi
      
      echo "✅ Pre-flight checks completed successfully"
    EOT
  }
  
  # Trigger re-run when configuration changes
  triggers = {
    proxmox_endpoint = var.proxmox_config.endpoint
    ssh_key_path     = var.ssh_config.private_key_path
    ssh_public_key   = md5(var.ssh_config.public_key)
    cluster_cidr     = var.k3s_config.cluster_cidr
    service_cidr     = var.k3s_config.service_cidr
  }
}

# Cross-variable validation checks
resource "null_resource" "cross_variable_validation" {
  # Validate cross-variable dependencies and configurations
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔍 Running cross-variable validation checks..."
      
      # Check for validation errors
      validation_errors='${jsonencode(local.actual_validation_errors)}'
      
      if [ "$validation_errors" != "[]" ] && [ "$validation_errors" != "null" ]; then
        echo "⚠️  Configuration warnings detected:"
        echo "$validation_errors" | sed 's/\[//g' | sed 's/\]//g' | sed 's/,/\n/g' | sed 's/"//g' | while read -r error; do
          if [ -n "$error" ]; then
            echo "   - $error"
          fi
        done
        echo ""
        echo "These are warnings and deployment will continue, but please review your configuration."
      else
        echo "✅ All cross-variable validations passed"
      fi
      
      # Additional logical validations
      echo "🔍 Running additional configuration checks..."
      
      # Check VM name doesn't conflict with common hostnames
      vm_name="${var.vm_config.name}"
      reserved_names="localhost router gateway dns dhcp proxy"
      for reserved in $reserved_names; do
        if [ "$vm_name" = "$reserved" ]; then
          echo "❌ ERROR: VM name '$vm_name' conflicts with reserved hostname '$reserved'"
          exit 1
        fi
      done
      echo "✅ VM name is not reserved"
      
      # Validate K3s version format if not 'latest'
      k3s_version="${var.k3s_config.version}"
      if [ "$k3s_version" != "latest" ]; then
        if ! echo "$k3s_version" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+'; then
          echo "❌ ERROR: K3s version '$k3s_version' is not in valid format (should be 'latest' or 'vX.Y.Z+k3sN')"
          exit 1
        fi
        echo "✅ K3s version format is valid"
      else
        echo "✅ Using latest K3s version"
      fi
      
      # Check for potential CIDR conflicts with common networks
      cluster_cidr="${var.k3s_config.cluster_cidr}"
      service_cidr="${var.k3s_config.service_cidr}"
      
      # Common network ranges that might conflict
      common_networks="192.168.1.0/24 192.168.0.0/24 10.0.0.0/24 172.16.0.0/24"
      
      for network in $common_networks; do
        network_prefix=$(echo "$network" | cut -d'.' -f1-2)
        cluster_prefix=$(echo "$cluster_cidr" | cut -d'.' -f1-2)
        service_prefix=$(echo "$service_cidr" | cut -d'.' -f1-2)
        
        if [ "$cluster_prefix" = "$network_prefix" ] || [ "$service_prefix" = "$network_prefix" ]; then
          echo "⚠️  WARNING: K3s CIDR ranges may conflict with common network $network"
          echo "   Cluster CIDR: $cluster_cidr"
          echo "   Service CIDR: $service_cidr"
          echo "   This may cause connectivity issues if the network is in use"
        fi
      done
      
      echo "✅ Cross-variable validation completed"
    EOT
  }
  
  # Run before other validations
  triggers = {
    vm_config = jsonencode(var.vm_config)
    k3s_config = jsonencode(var.k3s_config)
    network_config = jsonencode(var.network_config)
    validation_errors = jsonencode(local.actual_validation_errors)
  }
}

# Proxmox API connectivity validation
resource "null_resource" "proxmox_api_validation" {
  # Test Proxmox API authentication and basic functionality
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔐 Validating Proxmox API connectivity..."
      
      # Test API authentication using curl
      api_url="${var.proxmox_config.endpoint}/api2/json/version"
      
      # Prepare curl command with authentication
      if command -v curl >/dev/null 2>&1; then
        echo "Testing API authentication..."
        
        # Create temporary file for cookie storage
        cookie_file=$(mktemp)
        
        # Test login
        login_response=$(curl -s -k -d "username=${var.proxmox_config.username}&password=${var.proxmox_config.password}" \
          -X POST "${var.proxmox_config.endpoint}/api2/json/access/ticket" \
          -c "$cookie_file" \
          -w "%%{http_code}" -o /tmp/proxmox_login_response.json)
        
        if [ "$login_response" = "200" ]; then
          echo "✅ Proxmox API authentication successful"
          
          # Test basic API call to get version
          version_response=$(curl -s -k -b "$cookie_file" \
            "$api_url" \
            -w "%%{http_code}" -o /tmp/proxmox_version_response.json)
          
          if [ "$version_response" = "200" ]; then
            echo "✅ Proxmox API version check successful"
            
            # Extract and display Proxmox version
            if command -v jq >/dev/null 2>&1; then
              pve_version=$(jq -r '.data.version // "unknown"' /tmp/proxmox_version_response.json 2>/dev/null || echo "unknown")
              echo "   Proxmox VE Version: $pve_version"
            fi
          else
            echo "❌ ERROR: Proxmox API version check failed (HTTP $version_response)"
            echo "   API may be accessible but user may lack permissions"
            rm -f "$cookie_file" /tmp/proxmox_login_response.json /tmp/proxmox_version_response.json
            exit 1
          fi
          
          # Test node access
          node_response=$(curl -s -k -b "$cookie_file" \
            "${var.proxmox_config.endpoint}/api2/json/nodes/${var.proxmox_config.node}/status" \
            -w "%%{http_code}" -o /tmp/proxmox_node_response.json)
          
          if [ "$node_response" = "200" ]; then
            echo "✅ Proxmox node '${var.proxmox_config.node}' is accessible"
            
            # Check node status
            if command -v jq >/dev/null 2>&1; then
              node_status=$(jq -r '.data.status // "unknown"' /tmp/proxmox_node_response.json 2>/dev/null || echo "unknown")
              if [ "$node_status" = "online" ]; then
                echo "✅ Node status: online"
              else
                echo "⚠️  WARNING: Node status: $node_status"
              fi
            fi
          else
            echo "❌ ERROR: Cannot access Proxmox node '${var.proxmox_config.node}' (HTTP $node_response)"
            echo "   Please verify the node name and user permissions"
            rm -f "$cookie_file" /tmp/proxmox_login_response.json /tmp/proxmox_version_response.json /tmp/proxmox_node_response.json
            exit 1
          fi
          
          # Test storage access
          storage_response=$(curl -s -k -b "$cookie_file" \
            "${var.proxmox_config.endpoint}/api2/json/nodes/${var.proxmox_config.node}/storage/${var.vm_config.storage}/status" \
            -w "%%{http_code}" -o /tmp/proxmox_storage_response.json)
          
          if [ "$storage_response" = "200" ]; then
            echo "✅ Storage '${var.vm_config.storage}' is accessible"
            
            # Check storage status and space
            if command -v jq >/dev/null 2>&1; then
              storage_enabled=$(jq -r '.data.enabled // 0' /tmp/proxmox_storage_response.json 2>/dev/null || echo "0")
              if [ "$storage_enabled" = "1" ]; then
                echo "✅ Storage is enabled"
                
                # Show available space if available
                avail_bytes=$(jq -r '.data.avail // 0' /tmp/proxmox_storage_response.json 2>/dev/null || echo "0")
                if [ "$avail_bytes" -gt 0 ]; then
                  avail_gb=$((avail_bytes / 1024 / 1024 / 1024))
                  echo "   Available space: ${avail_gb}GB"
                fi
              else
                echo "⚠️  WARNING: Storage '${var.vm_config.storage}' is disabled"
              fi
            fi
          else
            echo "❌ ERROR: Cannot access storage '${var.vm_config.storage}' (HTTP $storage_response)"
            echo "   Please verify the storage name and availability"
            rm -f "$cookie_file" /tmp/proxmox_*_response.json
            exit 1
          fi
          
          # Test template existence
          template_response=$(curl -s -k -b "$cookie_file" \
            "${var.proxmox_config.endpoint}/api2/json/nodes/${var.proxmox_config.node}/qemu" \
            -w "%%{http_code}" -o /tmp/proxmox_vms_response.json)
          
          if [ "$template_response" = "200" ]; then
            if command -v jq >/dev/null 2>&1; then
              template_found=$(jq -r --arg template "${var.vm_config.template}" \
                '.data[] | select(.name == $template and .template == 1) | .name' \
                /tmp/proxmox_vms_response.json 2>/dev/null || echo "")
              
              if [ -n "$template_found" ]; then
                echo "✅ Template '${var.vm_config.template}' found and is marked as template"
              else
                echo "❌ ERROR: Template '${var.vm_config.template}' not found or not marked as template"
                echo "   Please verify the template name and ensure it exists on node '${var.proxmox_config.node}'"
                rm -f "$cookie_file" /tmp/proxmox_*_response.json
                exit 1
              fi
            else
              echo "⚠️  WARNING: Cannot verify template existence (jq not available)"
            fi
          else
            echo "⚠️  WARNING: Cannot list VMs to verify template (HTTP $template_response)"
          fi
          
        else
          echo "❌ ERROR: Proxmox API authentication failed (HTTP $login_response)"
          echo "   Please verify username and password"
          rm -f "$cookie_file" /tmp/proxmox_login_response.json
          exit 1
        fi
        
        # Cleanup temporary files
        rm -f "$cookie_file" /tmp/proxmox_*_response.json
        
      else
        echo "⚠️  WARNING: curl not available, skipping Proxmox API validation"
        echo "   Install curl for comprehensive API validation"
      fi
      
      echo "✅ Proxmox API validation completed"
    EOT
  }
  
  # Run after cross-variable and pre-flight checks
  depends_on = [
    null_resource.cross_variable_validation,
    null_resource.preflight_checks
  ]
  
  # Trigger re-run when Proxmox configuration changes
  triggers = {
    proxmox_endpoint = var.proxmox_config.endpoint
    proxmox_username = var.proxmox_config.username
    proxmox_password = md5(var.proxmox_config.password)
    proxmox_node     = var.proxmox_config.node
    vm_template      = var.vm_config.template
    vm_storage       = var.vm_config.storage
  }
}

# Local values for computed configurations and cross-variable validation
locals {
  # Parse IP address and netmask from CIDR notation
  ip_parts = var.network_config.ip_address != "dhcp" ? split("/", var.network_config.ip_address) : ["", ""]
  static_ip = var.network_config.ip_address != "dhcp" ? local.ip_parts[0] : "dhcp"
  netmask = var.network_config.ip_address != "dhcp" ? local.ip_parts[1] : ""
  
  # VM hostname derived from VM name
  hostname = var.vm_config.name
  
  # K3s node name - use VM name if not specified
  k3s_node_name = var.k3s_config.node_name != "" ? var.k3s_config.node_name : var.vm_config.name
  
  # K3s disabled components as comma-separated string
  k3s_disable_components = length(var.k3s_config.disable) > 0 ? join(",", var.k3s_config.disable) : ""
  
  # Cross-variable validation checks
  validation_errors = [
    # Check if static IP and gateway are in the same subnet (basic check)
    var.network_config.ip_address != "dhcp" && var.network_config.gateway != "" ? (
      # Extract first three octets for basic subnet comparison
      substr(local.static_ip, 0, length(local.static_ip) - length(split(".", local.static_ip)[3]) - 1) !=
      substr(var.network_config.gateway, 0, length(var.network_config.gateway) - length(split(".", var.network_config.gateway)[3]) - 1) ?
      "Static IP and gateway appear to be in different subnets" : null
    ) : null,
    
    # Check for reasonable VM resource allocation
    var.vm_config.cores > 16 && var.vm_config.memory < 4096 ? 
      "High CPU count (${var.vm_config.cores}) with low memory (${var.vm_config.memory}MB) may cause performance issues" : null,
    
    # Check disk size is reasonable for K3s
    can(regex("^[0-9]+[GM]$", var.vm_config.disk_size)) ? (
      tonumber(regex("^([0-9]+)", var.vm_config.disk_size)[0]) < 10 && 
      substr(var.vm_config.disk_size, -1, 1) == "G" ?
      "Disk size less than 10GB may be insufficient for K3s and container images" : null
    ) : null,
    
    # Validate K3s token strength
    length(var.k3s_config.token) < 32 ?
      "K3s token should be at least 32 characters for better security" : null
  ]
  
  # Filter out null validation errors
  actual_validation_errors = [for error in local.validation_errors : error if error != null]
  
  # Cloud-init configuration rendered from template
  cloud_init_config = templatefile("${path.module}/cloud-init.tpl", {
    username         = var.ssh_config.username
    ssh_public_key   = var.ssh_config.public_key
    hostname         = local.hostname
    domain           = var.network_config.domain
    static_ip        = local.static_ip
    network_interface = var.network_config.interface_name
    gateway          = var.network_config.gateway
    dns_server_1     = var.network_config.nameserver
    dns_server_2     = var.network_config.nameserver_2
    timezone         = var.system_config.timezone
    locale           = var.system_config.locale
    vm_ip            = var.network_config.ip_address != "dhcp" ? local.static_ip : "DHCP_ASSIGNED"
    
    # K3s configuration variables
    k3s_version      = var.k3s_config.version
    k3s_token        = var.k3s_config.token
    k3s_node_name    = local.k3s_node_name
    k3s_disable_components = local.k3s_disable_components
    k3s_server_args  = var.k3s_config.server_args
    k3s_cluster_cidr = var.k3s_config.cluster_cidr
    k3s_service_cidr = var.k3s_config.service_cidr
  })
}

# Proxmox VM resource definition
resource "proxmox_vm_qemu" "k3s_vm" {
  # Basic VM configuration
  name        = var.vm_config.name
  desc        = var.vm_config.description
  target_node = var.proxmox_config.node
  
  # VM specifications from variables
  cores   = var.vm_config.cores
  memory  = var.vm_config.memory
  sockets = 1
  
  # Boot and BIOS settings
  bios = "ovmf"
  boot = "order=scsi0;ide2;net0"
  
  # QEMU guest agent
  agent = 1
  
  # Use existing template
  clone      = var.vm_config.template
  full_clone = true
  
  # EFI disk configuration
  efidisk {
    efitype = "4m"
    storage = var.vm_config.storage
  }
  
  # Main system disk
  disk {
    slot    = 0
    type    = "scsi"
    storage = var.vm_config.storage
    size    = var.vm_config.disk_size
    format  = "qcow2"
    cache   = "writethrough"
    backup  = 1
  }
  
  # Network interface configuration
  network {
    model  = "virtio"
    bridge = var.vm_config.network
  }
  
  # Cloud-init drive
  cloudinit_cdrom_storage = var.vm_config.storage
  
  # IP configuration - static or DHCP
  ipconfig0 = var.network_config.ip_address != "dhcp" ? "ip=${var.network_config.ip_address},gw=${var.network_config.gateway}" : "ip=dhcp"
  
  # SSH keys for cloud-init
  sshkeys = var.ssh_config.public_key
  
  # Cloud-init user configuration
  ciuser = var.ssh_config.username
  
  # Custom cloud-init configuration
  cicustom = "user=local:snippets/${var.vm_config.name}-user.yml"
  
  # VM lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignore changes to network configuration after initial creation
      network,
      # Ignore changes to cloud-init after initial setup
      cicustom,
      sshkeys,
    ]
  }
  
  # Ensure VM is created after all validations and cloud-init snippet is uploaded
  depends_on = [
    null_resource.cross_variable_validation,
    null_resource.preflight_checks,
    null_resource.proxmox_api_validation,
    null_resource.upload_cloud_init
  ]
}

# Create cloud-init user data file as local snippet
resource "local_file" "cloud_init_user_data" {
  filename = "/tmp/${var.vm_config.name}-user.yml"
  content  = local.cloud_init_config
  
  # Ensure the file is created with proper permissions
  file_permission = "0644"
}

# Copy cloud-init file to Proxmox snippets directory
resource "null_resource" "upload_cloud_init" {
  # Upload the cloud-init configuration to Proxmox
  provisioner "local-exec" {
    command = <<-EOT
      scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        /tmp/${var.vm_config.name}-user.yml \
        root@${replace(var.proxmox_config.endpoint, "https://", "")}:/var/lib/vz/snippets/${var.vm_config.name}-user.yml
    EOT
  }
  
  # Trigger re-upload when cloud-init content changes
  triggers = {
    cloud_init_content = md5(local.cloud_init_config)
  }
  
  depends_on = [
    null_resource.cross_variable_validation,
    null_resource.proxmox_api_validation,
    local_file.cloud_init_user_data
  ]
}

# SSH connection resource for post-deployment access with enhanced error handling
resource "null_resource" "wait_for_vm" {
  # Wait for VM to be accessible via SSH with comprehensive validation
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔄 Waiting for VM to be accessible via SSH..."
      timeout=600
      counter=0
      vm_ip="${var.network_config.ip_address != "dhcp" ? local.static_ip : "DHCP_ASSIGNED"}"
      
      # Function to validate IP address format
      validate_ip() {
        local ip=$1
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
          IFS='.' read -ra ADDR <<< "$ip"
          for i in "$${ADDR[@]}"; do
            if [[ $i -gt 255 ]]; then
              return 1
            fi
          done
          return 0
        fi
        return 1
      }
      
      # If using DHCP, get the IP from Terraform's VM resource
      if [ "$vm_ip" = "DHCP_ASSIGNED" ]; then
        echo "VM using DHCP, getting IP from Terraform state..."
        
        # Try multiple times to get the IP as it may take time to be assigned
        dhcp_attempts=0
        max_dhcp_attempts=12
        
        while [ $dhcp_attempts -lt $max_dhcp_attempts ]; do
          vm_ip="${proxmox_vm_qemu.k3s_vm.default_ipv4_address}"
          echo "Attempt $((dhcp_attempts + 1))/$max_dhcp_attempts - VM IP from Terraform: $vm_ip"
          
          if [ -n "$vm_ip" ] && [ "$vm_ip" != "null" ] && [ "$vm_ip" != "" ]; then
            if validate_ip "$vm_ip"; then
              echo "✅ Valid DHCP IP obtained: $vm_ip"
              break
            else
              echo "⚠️  Invalid IP format received: $vm_ip"
            fi
          fi
          
          echo "Waiting for DHCP IP assignment..."
          sleep 15
          dhcp_attempts=$((dhcp_attempts + 1))
        done
        
        if [ $dhcp_attempts -ge $max_dhcp_attempts ]; then
          echo "❌ ERROR: Failed to obtain valid DHCP IP after $max_dhcp_attempts attempts"
          echo "   Last received IP: $vm_ip"
          echo "   Please check VM network configuration and DHCP server"
          exit 1
        fi
      else
        echo "Using static IP: $vm_ip"
        if ! validate_ip "$vm_ip"; then
          echo "❌ ERROR: Invalid static IP address format: $vm_ip"
          exit 1
        fi
      fi
      
      # Validate we have a proper IP address
      if [ -z "$vm_ip" ] || [ "$vm_ip" = "null" ] || [ "$vm_ip" = "DHCP_ASSIGNED" ]; then
        echo "❌ ERROR: No valid IP address available for VM"
        echo "   VM IP: $vm_ip"
        exit 1
      fi
      
      echo "🔍 Testing network connectivity to $vm_ip..."
      
      # Test basic network connectivity first
      if command -v ping >/dev/null 2>&1; then
        echo "Testing ICMP connectivity..."
        if ping -c 3 -W 5 "$vm_ip" >/dev/null 2>&1; then
          echo "✅ ICMP ping successful"
        else
          echo "⚠️  ICMP ping failed (may be blocked by firewall)"
        fi
      fi
      
      # Test SSH port connectivity
      if command -v nc >/dev/null 2>&1; then
        echo "Testing SSH port connectivity..."
        if nc -z -w5 "$vm_ip" 22 2>/dev/null; then
          echo "✅ SSH port (22) is open"
        else
          echo "⚠️  SSH port (22) is not responding"
        fi
      fi
      
      # Wait for SSH to be available with detailed logging
      echo "🔐 Testing SSH authentication to $vm_ip..."
      ssh_success=false
      
      while [ $counter -lt $timeout ]; do
        # Test SSH connection with detailed error handling
        ssh_output=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 \
           -o BatchMode=yes -o PasswordAuthentication=no \
           -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
           "echo 'SSH connection successful'; whoami; uptime" 2>&1)
        ssh_exit_code=$?
        
        if [ $ssh_exit_code -eq 0 ]; then
          echo "✅ SSH connection established to $vm_ip"
          echo "   Connection details:"
          echo "$ssh_output" | sed 's/^/   /'
          ssh_success=true
          break
        else
          # Analyze SSH error for better diagnostics
          if echo "$ssh_output" | grep -q "Connection refused"; then
            echo "🔄 SSH service not ready yet (connection refused) - attempt $((counter / 10 + 1))"
          elif echo "$ssh_output" | grep -q "No route to host"; then
            echo "❌ ERROR: No route to host $vm_ip"
            echo "   Please check network configuration"
            exit 1
          elif echo "$ssh_output" | grep -q "Permission denied"; then
            echo "❌ ERROR: SSH authentication failed"
            echo "   Please check SSH key configuration"
            echo "   SSH output: $ssh_output"
            exit 1
          elif echo "$ssh_output" | grep -q "Host key verification failed"; then
            echo "⚠️  Host key verification issue (should be ignored with our settings)"
          else
            echo "🔄 SSH not ready - attempt $((counter / 10 + 1)) (waiting...)"
            if [ $((counter % 60)) -eq 0 ] && [ $counter -gt 0 ]; then
              echo "   SSH error details: $ssh_output"
            fi
          fi
        fi
        
        sleep 10
        counter=$((counter + 10))
        
        # Show progress every minute
        if [ $((counter % 60)) -eq 0 ]; then
          echo "   Progress: $counter/$timeout seconds elapsed"
        fi
      done
      
      if [ "$ssh_success" != "true" ]; then
        echo "❌ ERROR: Failed to establish SSH connection within $timeout seconds"
        echo "   Final SSH attempt output:"
        echo "$ssh_output"
        echo ""
        echo "🔧 Troubleshooting suggestions:"
        echo "   1. Check if VM is running: VM IP $vm_ip"
        echo "   2. Verify SSH key: ${var.ssh_config.private_key_path}"
        echo "   3. Check cloud-init logs on VM"
        echo "   4. Verify network configuration"
        echo "   5. Check firewall rules"
        exit 1
      fi
      
      # Additional post-connection validation
      echo "🔍 Running post-connection validation..."
      
      # Check if cloud-init has completed
      cloud_init_status=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
        "cloud-init status --wait --long 2>/dev/null || echo 'cloud-init command not available'" 2>/dev/null)
      
      if echo "$cloud_init_status" | grep -q "done"; then
        echo "✅ Cloud-init completed successfully"
      elif echo "$cloud_init_status" | grep -q "running"; then
        echo "🔄 Cloud-init still running, waiting for completion..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "cloud-init status --wait" 2>/dev/null || echo "⚠️  Could not wait for cloud-init completion"
      else
        echo "⚠️  Cloud-init status unclear: $cloud_init_status"
      fi
      
      # Check system readiness
      echo "🖥️  Checking system readiness..."
      system_info=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
        "echo 'Hostname:' \$(hostname); echo 'OS:' \$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"'); echo 'Uptime:' \$(uptime | cut -d',' -f1)" 2>/dev/null)
      
      if [ -n "$system_info" ]; then
        echo "✅ System information:"
        echo "$system_info" | sed 's/^/   /'
      fi
      
      echo "✅ VM is ready and accessible via SSH at $vm_ip"
    EOT
  }
  
  # Enhanced error handling with retry on failure
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🧹 Cleaning up temporary files for VM ${var.vm_config.name}..."
      rm -f /tmp/${var.vm_config.name}-*.yml
      rm -f /tmp/${var.vm_config.name}-*.yaml
      rm -f /tmp/${var.vm_config.name}-*.sh
      echo "✅ Cleanup completed"
    EOT
  }
  
  depends_on = [
    proxmox_vm_qemu.k3s_vm
  ]
  
  # Trigger re-run when VM or network configuration changes
  triggers = {
    vm_id = proxmox_vm_qemu.k3s_vm.vmid
    vm_ip = var.network_config.ip_address
    ssh_key = md5(var.ssh_config.public_key)
  }
}

# Extract kubeconfig from VM with comprehensive error handling
resource "null_resource" "extract_kubeconfig" {
  # Extract kubeconfig file from the VM with validation and error handling
  provisioner "local-exec" {
    command = <<-EOT
      echo "📋 Extracting kubeconfig from VM..."
      
      # Determine VM IP address
      vm_ip="${var.network_config.ip_address != "dhcp" ? local.static_ip : "DHCP_ASSIGNED"}"
      
      # If using DHCP, get the IP from Proxmox VM resource
      if [ "$vm_ip" = "DHCP_ASSIGNED" ]; then
        vm_ip="${proxmox_vm_qemu.k3s_vm.default_ipv4_address}"
        echo "Using DHCP assigned IP: $vm_ip"
      fi
      
      # Validate IP address
      if [ -z "$vm_ip" ] || [ "$vm_ip" = "null" ]; then
        echo "❌ ERROR: No valid VM IP address available"
        exit 1
      fi
      
      echo "🔍 Checking K3s installation status..."
      
      # Check if K3s service is installed and running
      k3s_service_status=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
        "systemctl is-active k3s 2>/dev/null || echo 'not-running'" 2>/dev/null)
      
      if [ "$k3s_service_status" != "active" ]; then
        echo "⚠️  K3s service status: $k3s_service_status"
        echo "🔍 Checking K3s installation..."
        
        # Check if K3s binary exists
        k3s_binary_check=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "which k3s 2>/dev/null || echo 'not-found'" 2>/dev/null)
        
        if [ "$k3s_binary_check" = "not-found" ]; then
          echo "❌ ERROR: K3s binary not found. Installation may have failed."
          echo "🔧 Checking cloud-init logs for installation errors..."
          
          cloud_init_logs=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
            "sudo tail -50 /var/log/cloud-init-output.log 2>/dev/null | grep -i k3s || echo 'No K3s logs found'" 2>/dev/null)
          
          echo "Cloud-init K3s logs:"
          echo "$cloud_init_logs"
          exit 1
        fi
        
        echo "🔄 K3s binary found, attempting to start service..."
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "sudo systemctl start k3s" 2>/dev/null || echo "Failed to start K3s service"
      fi
      
      # Wait for K3s to be fully ready with enhanced monitoring
      echo "🔄 Waiting for K3s cluster to be ready..."
      timeout=600
      counter=0
      k3s_ready=false
      
      while [ $counter -lt $timeout ]; do
        # Check multiple indicators of K3s readiness
        
        # 1. Check if kubeconfig file exists
        kubeconfig_exists=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "test -f /etc/rancher/k3s/k3s.yaml && echo 'exists' || echo 'missing'" 2>/dev/null)
        
        if [ "$kubeconfig_exists" = "missing" ]; then
          echo "🔄 Waiting for kubeconfig file... ($counter/$timeout)"
          sleep 10
          counter=$((counter + 10))
          continue
        fi
        
        # 2. Check if kubectl can connect to API server
        kubectl_test=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "sudo kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml --request-timeout=10s 2>&1" 2>/dev/null)
        kubectl_exit_code=$?
        
        if [ $kubectl_exit_code -eq 0 ]; then
          echo "✅ kubectl can connect to API server"
          
          # 3. Check if node is ready
          node_ready=$(echo "$kubectl_test" | grep -c "Ready" || echo "0")
          if [ "$node_ready" -gt 0 ]; then
            echo "✅ K3s node is ready!"
            k3s_ready=true
            break
          else
            echo "🔄 Node not ready yet, current status:"
            echo "$kubectl_test" | sed 's/^/   /'
          fi
        else
          # Analyze kubectl error
          if echo "$kubectl_test" | grep -q "connection refused"; then
            echo "🔄 API server not ready (connection refused) - attempt $((counter / 10 + 1))"
          elif echo "$kubectl_test" | grep -q "timeout"; then
            echo "🔄 API server timeout - attempt $((counter / 10 + 1))"
          else
            echo "🔄 kubectl error: $kubectl_test"
          fi
        fi
        
        sleep 10
        counter=$((counter + 10))
        
        # Show progress and service status every minute
        if [ $((counter % 60)) -eq 0 ]; then
          echo "   Progress: $counter/$timeout seconds elapsed"
          
          # Show K3s service status for debugging
          service_status=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
            -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
            "sudo systemctl status k3s --no-pager -l | head -10" 2>/dev/null || echo "Could not get service status")
          echo "   K3s service status:"
          echo "$service_status" | sed 's/^/     /'
        fi
      done
      
      if [ "$k3s_ready" != "true" ]; then
        echo "❌ ERROR: K3s cluster not ready within $timeout seconds"
        echo ""
        echo "🔧 Diagnostic information:"
        
        # Get detailed service status
        echo "K3s service status:"
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "sudo systemctl status k3s --no-pager -l" 2>/dev/null | sed 's/^/  /' || echo "  Could not get service status"
        
        # Get recent logs
        echo ""
        echo "Recent K3s logs:"
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
          -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
          "sudo journalctl -u k3s --no-pager -n 20" 2>/dev/null | sed 's/^/  /' || echo "  Could not get logs"
        
        exit 1
      fi
      
      # Extract and validate kubeconfig
      echo "📋 Extracting kubeconfig..."
      kubeconfig_content=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        -i ${var.ssh_config.private_key_path} ${var.ssh_config.username}@$vm_ip \
        "sudo cat /etc/rancher/k3s/k3s.yaml" 2>/dev/null)
      
      if [ -z "$kubeconfig_content" ]; then
        echo "❌ ERROR: Failed to extract kubeconfig content"
        exit 1
      fi
      
      # Validate kubeconfig structure
      if ! echo "$kubeconfig_content" | grep -q "apiVersion:"; then
        echo "❌ ERROR: Invalid kubeconfig format (missing apiVersion)"
        exit 1
      fi
      
      if ! echo "$kubeconfig_content" | grep -q "clusters:"; then
        echo "❌ ERROR: Invalid kubeconfig format (missing clusters)"
        exit 1
      fi
      
      # Save original kubeconfig
      echo "$kubeconfig_content" > /tmp/${var.vm_config.name}-kubeconfig.yaml
      
      # Create modified version with external access
      echo "🔧 Configuring kubeconfig for external access..."
      
      # Replace localhost/127.0.0.1 with actual VM IP
      sed -i.bak "s/127.0.0.1/$vm_ip/g" /tmp/${var.vm_config.name}-kubeconfig.yaml
      sed -i.bak "s/localhost/$vm_ip/g" /tmp/${var.vm_config.name}-kubeconfig.yaml
      
      # Update cluster name and context for clarity
      sed -i.bak "s/default/${var.vm_config.name}/g" /tmp/${var.vm_config.name}-kubeconfig.yaml
      
      # Validate the modified kubeconfig
      if command -v kubectl >/dev/null 2>&1; then
        echo "🔍 Validating modified kubeconfig..."
        if kubectl --kubeconfig=/tmp/${var.vm_config.name}-kubeconfig.yaml cluster-info --request-timeout=10s >/dev/null 2>&1; then
          echo "✅ Kubeconfig validation successful"
        else
          echo "⚠️  Kubeconfig validation failed (cluster may not be externally accessible)"
          echo "   This is normal if there are firewall restrictions"
        fi
      fi
      
      # Show cluster information
      echo ""
      echo "🎉 Kubeconfig extraction completed successfully!"
      echo "📁 Kubeconfig saved to: /tmp/${var.vm_config.name}-kubeconfig.yaml"
      echo "🌐 Cluster server: https://$vm_ip:6443"
      echo "🏷️  Cluster name: ${var.vm_config.name}"
      echo ""
      echo "💡 Usage examples:"
      echo "   export KUBECONFIG=/tmp/${var.vm_config.name}-kubeconfig.yaml"
      echo "   kubectl get nodes"
      echo "   kubectl --kubeconfig=/tmp/${var.vm_config.name}-kubeconfig.yaml get pods -A"
      
      # Clean up backup files
      rm -f /tmp/${var.vm_config.name}-kubeconfig.yaml.bak
    EOT
  }
  
  # Enhanced error handling for kubeconfig extraction failures
  provisioner "local-exec" {
    when = destroy
    command = <<-EOT
      echo "🧹 Cleaning up kubeconfig files for ${var.vm_config.name}..."
      rm -f /tmp/${var.vm_config.name}-kubeconfig.yaml*
      echo "✅ Kubeconfig cleanup completed"
    EOT
  }
  
  # Trigger re-extraction when VM or K3s configuration changes
  triggers = {
    vm_id = proxmox_vm_qemu.k3s_vm.vmid
    k3s_token = var.k3s_config.token
    k3s_version = var.k3s_config.version
    vm_name = var.vm_config.name
  }
  
  depends_on = [
    null_resource.wait_for_vm
  ]
}

# Read the extracted kubeconfig file
data "local_file" "kubeconfig" {
  filename = "/tmp/${var.vm_config.name}-kubeconfig.yaml"
  
  depends_on = [
    null_resource.extract_kubeconfig
  ]
}

# Create a helper script for easy cluster access
resource "local_file" "cluster_access_script" {
  filename = "/tmp/${var.vm_config.name}-cluster-access.sh"
  content = <<-EOT
#!/bin/bash
# K3s Cluster Access Helper Script
# Generated by Terraform for cluster: ${var.vm_config.name}

set -e

CLUSTER_NAME="${var.vm_config.name}"
VM_IP="${var.network_config.ip_address != "dhcp" ? local.static_ip : "DHCP_ASSIGNED"}"
SSH_USER="${var.ssh_config.username}"
SSH_KEY="${var.ssh_config.private_key_path}"
KUBECONFIG_PATH="/tmp/$${CLUSTER_NAME}-kubeconfig.yaml"

echo "🚀 K3s Cluster Access Helper"
echo "Cluster: $CLUSTER_NAME"
echo "================================"

# Function to get VM IP if using DHCP
get_vm_ip() {
    if [ "$VM_IP" = "DHCP_ASSIGNED" ]; then
        echo "🔍 Detecting VM IP address..."
        # This would need to be implemented based on your Proxmox setup
        # For now, we'll use a placeholder
        echo "⚠️  DHCP IP detection not implemented in this script"
        echo "   Please check Proxmox console for VM IP address"
        exit 1
    fi
    echo "$VM_IP"
}

# Function to test SSH connectivity
test_ssh() {
    local ip=$(get_vm_ip)
    echo "🔐 Testing SSH connection to $ip..."
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$SSH_KEY" "$SSH_USER@$ip" "echo 'SSH OK'" >/dev/null 2>&1; then
        echo "✅ SSH connection successful"
        return 0
    else
        echo "❌ SSH connection failed"
        return 1
    fi
}

# Function to test kubectl access
test_kubectl() {
    echo "🎯 Testing kubectl access..."
    if [ -f "$KUBECONFIG_PATH" ]; then
        if kubectl --kubeconfig="$KUBECONFIG_PATH" get nodes >/dev/null 2>&1; then
            echo "✅ Kubectl access successful"
            kubectl --kubeconfig="$KUBECONFIG_PATH" get nodes
            return 0
        else
            echo "❌ Kubectl access failed"
            return 1
        fi
    else
        echo "❌ Kubeconfig file not found: $KUBECONFIG_PATH"
        return 1
    fi
}

# Function to show cluster info
show_cluster_info() {
    echo "📊 Cluster Information:"
    echo "   Cluster Name: $CLUSTER_NAME"
    echo "   VM IP: $(get_vm_ip)"
    echo "   SSH Command: ssh -i $SSH_KEY $SSH_USER@$(get_vm_ip)"
    echo "   Kubeconfig: $KUBECONFIG_PATH"
    echo "   Kubectl: kubectl --kubeconfig=$KUBECONFIG_PATH"
}

# Function to set up local kubeconfig
setup_kubeconfig() {
    echo "⚙️  Setting up local kubeconfig..."
    if [ -f "$KUBECONFIG_PATH" ]; then
        echo "   Kubeconfig already exists: $KUBECONFIG_PATH"
        echo "   To use this cluster, run:"
        echo "   export KUBECONFIG=$KUBECONFIG_PATH"
    else
        echo "❌ Kubeconfig not found. Run 'terraform apply' first."
        exit 1
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  info      Show cluster information"
    echo "  ssh       Test SSH connection"
    echo "  kubectl   Test kubectl access"
    echo "  setup     Set up local kubeconfig"
    echo "  connect   SSH into the cluster node"
    echo "  logs      Show K3s service logs"
    echo "  status    Show cluster status"
    echo ""
    echo "Examples:"
    echo "  $0 info"
    echo "  $0 kubectl"
    echo "  $0 connect"
}

# Function to connect via SSH
connect_ssh() {
    local ip=$(get_vm_ip)
    echo "🔗 Connecting to $CLUSTER_NAME ($ip)..."
    ssh -i "$SSH_KEY" "$SSH_USER@$ip"
}

# Function to show K3s logs
show_logs() {
    local ip=$(get_vm_ip)
    echo "📋 Showing K3s logs from $CLUSTER_NAME..."
    ssh -i "$SSH_KEY" "$SSH_USER@$ip" "sudo journalctl -u k3s -f"
}

# Function to show cluster status
show_status() {
    echo "📈 Cluster Status for $CLUSTER_NAME:"
    test_ssh && test_kubectl
    echo ""
    echo "🏷️  Cluster Details:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" cluster-info 2>/dev/null || echo "❌ Could not get cluster info"
    echo ""
    echo "🖥️  Nodes:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get nodes -o wide 2>/dev/null || echo "❌ Could not get nodes"
    echo ""
    echo "🏃 System Pods:"
    kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -n kube-system 2>/dev/null || echo "❌ Could not get system pods"
}

# Main script logic
case "${1:-info}" in
    "info")
        show_cluster_info
        ;;
    "ssh")
        test_ssh
        ;;
    "kubectl")
        test_kubectl
        ;;
    "setup")
        setup_kubeconfig
        ;;
    "connect")
        connect_ssh
        ;;
    "logs")
        show_logs
        ;;
    "status")
        show_status
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac
EOT
  
  file_permission = "0755"
  
  depends_on = [
    null_resource.extract_kubeconfig
  ]
}

# Create kubeconfig validation script
resource "local_file" "kubeconfig_validator" {
  filename = "/tmp/${var.vm_config.name}-validate-kubeconfig.sh"
  content = <<-EOT
#!/bin/bash
# Kubeconfig Validation Script
# Generated by Terraform for cluster: ${var.vm_config.name}

set -e

CLUSTER_NAME="${var.vm_config.name}"
KUBECONFIG_PATH="/tmp/$${CLUSTER_NAME}-kubeconfig.yaml"
EXPECTED_SERVER="https://${var.network_config.ip_address != "dhcp" ? local.static_ip : "DHCP_IP"}:6443"

echo "🔍 Validating kubeconfig for cluster: $CLUSTER_NAME"
echo "=================================================="

# Check if kubeconfig file exists
if [ ! -f "$KUBECONFIG_PATH" ]; then
    echo "❌ Kubeconfig file not found: $KUBECONFIG_PATH"
    echo "   Run 'terraform apply' to generate the kubeconfig"
    exit 1
fi

echo "✅ Kubeconfig file exists: $KUBECONFIG_PATH"

# Validate kubeconfig structure
echo "🔍 Validating kubeconfig structure..."

# Check for required sections
if ! grep -q "apiVersion:" "$KUBECONFIG_PATH"; then
    echo "❌ Invalid kubeconfig: missing apiVersion"
    exit 1
fi

if ! grep -q "clusters:" "$KUBECONFIG_PATH"; then
    echo "❌ Invalid kubeconfig: missing clusters section"
    exit 1
fi

if ! grep -q "users:" "$KUBECONFIG_PATH"; then
    echo "❌ Invalid kubeconfig: missing users section"
    exit 1
fi

if ! grep -q "contexts:" "$KUBECONFIG_PATH"; then
    echo "❌ Invalid kubeconfig: missing contexts section"
    exit 1
fi

echo "✅ Kubeconfig structure is valid"

# Check server URL
echo "🔍 Validating server URL..."
SERVER_URL=$(grep "server:" "$KUBECONFIG_PATH" | awk '{print $2}' | tr -d ' ')

if [ "$SERVER_URL" != "$EXPECTED_SERVER" ]; then
    echo "⚠️  Server URL mismatch:"
    echo "   Expected: $EXPECTED_SERVER"
    echo "   Found: $SERVER_URL"
else
    echo "✅ Server URL is correct: $SERVER_URL"
fi

# Test kubectl connectivity
echo "🔍 Testing kubectl connectivity..."
if command -v kubectl >/dev/null 2>&1; then
    if kubectl --kubeconfig="$KUBECONFIG_PATH" cluster-info --request-timeout=10s >/dev/null 2>&1; then
        echo "✅ Kubectl connectivity successful"
        
        # Get cluster info
        echo ""
        echo "📊 Cluster Information:"
        kubectl --kubeconfig="$KUBECONFIG_PATH" cluster-info
        
        echo ""
        echo "🖥️  Cluster Nodes:"
        kubectl --kubeconfig="$KUBECONFIG_PATH" get nodes -o wide
        
        echo ""
        echo "🏃 System Pods Status:"
        kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -n kube-system --no-headers | wc -l | xargs echo "Total system pods:"
        kubectl --kubeconfig="$KUBECONFIG_PATH" get pods -n kube-system --field-selector=status.phase=Running --no-headers | wc -l | xargs echo "Running pods:"
        
    else
        echo "❌ Kubectl connectivity failed"
        echo "   Check if the cluster is running and accessible"
        exit 1
    fi
else
    echo "⚠️  kubectl not found in PATH"
    echo "   Install kubectl to test cluster connectivity"
fi

echo ""
echo "🎉 Kubeconfig validation completed successfully!"
echo ""
echo "💡 Usage examples:"
echo "   export KUBECONFIG=$KUBECONFIG_PATH"
echo "   kubectl get nodes"
echo "   kubectl get pods -A"
echo ""
echo "   Or use directly:"
echo "   kubectl --kubeconfig=$KUBECONFIG_PATH get nodes"
EOT
  
  file_permission = "0755"
  
  depends_on = [
    null_resource.extract_kubeconfig
  ]
}