#cloud-config

# User configuration
users:
  - name: ${username}
    groups: [adm, audio, cdrom, dialout, dip, floppy, lxd, netdev, plugdev, sudo, video]
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${ssh_public_key}

# Hostname configuration
hostname: ${hostname}
fqdn: ${hostname}.${domain}

# Package management
package_update: true
package_upgrade: true
packages:
  - curl
  - wget
  - git
  - htop
  - vim
  - net-tools
  - ca-certificates
  - gnupg
  - lsb-release
  - software-properties-common
  - apt-transport-https

# Network configuration
%{if static_ip != "dhcp"}
network:
  version: 2
  ethernets:
    ${network_interface}:
      dhcp4: false
      addresses:
        - ${static_ip}
      gateway4: ${gateway}
      nameservers:
        addresses:
          - ${dns_server_1}
          - ${dns_server_2}
%{else}
# Using DHCP - no static network configuration needed
%{endif}

# System configuration
timezone: ${timezone}
locale: ${locale}

# SSH configuration
ssh_pwauth: false
disable_root: true
ssh:
  emit_keys_to_console: false

# File system setup
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

# Run commands during boot
runcmd:
  # Update system clock
  - timedatectl set-timezone ${timezone}
  
  # Ensure SSH service is running
  - systemctl enable ssh
  - systemctl start ssh
  
  # Set proper permissions for user home directory
  - chown -R ${username}:${username} /home/${username}
  
  # Create .ssh directory with proper permissions
  - mkdir -p /home/${username}/.ssh
  - chmod 700 /home/${username}/.ssh
  - chown ${username}:${username} /home/${username}/.ssh
  
  # Update package cache one more time
  - apt-get update
  
  # Install Docker (prerequisite for K3s)
  - curl -fsSL https://get.docker.com -o get-docker.sh
  - sh get-docker.sh
  - usermod -aG docker ${username}
  - systemctl enable docker
  - systemctl start docker
  
  # Prepare system for K3s
  - echo 'net.bridge.bridge-nf-call-iptables = 1' >> /etc/sysctl.conf
  - echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
  - sysctl -p
  
  # Create directory for K3s configuration
  - mkdir -p /etc/rancher/k3s
  - chown -R ${username}:${username} /etc/rancher/k3s
  
  # Install K3s server with embedded etcd
  - |
    export INSTALL_K3S_VERSION="${k3s_version}"
    export K3S_TOKEN="${k3s_token}"
    export K3S_NODE_NAME="${k3s_node_name}"
    curl -sfL https://get.k3s.io | sh -s - server \
      --cluster-init \
      --disable="${k3s_disable_components}" \
      --cluster-cidr="${k3s_cluster_cidr}" \
      --service-cidr="${k3s_service_cidr}" \
      ${k3s_server_args}
  
  # Wait for K3s to be ready
  - |
    echo "Waiting for K3s to be ready..."
    timeout=300
    counter=0
    while [ $counter -lt $timeout ]; do
      if kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml >/dev/null 2>&1; then
        echo "K3s is ready!"
        break
      fi
      echo "Waiting for K3s... ($counter/$timeout)"
      sleep 5
      counter=$((counter + 5))
    done
    
    if [ $counter -ge $timeout ]; then
      echo "ERROR: K3s failed to start within $timeout seconds"
      exit 1
    fi
  
  # Configure kubectl access for user
  - mkdir -p /home/${username}/.kube
  - cp /etc/rancher/k3s/k3s.yaml /home/${username}/.kube/config
  - chown -R ${username}:${username} /home/${username}/.kube
  - chmod 600 /home/${username}/.kube/config
  
  # Verify K3s installation and cluster health
  - |
    echo "Verifying K3s cluster health..."
    kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml
    kubectl get pods -A --kubeconfig=/etc/rancher/k3s/k3s.yaml
    
    # Check if all system pods are running
    kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s --kubeconfig=/etc/rancher/k3s/k3s.yaml
    
    echo "K3s cluster is healthy and ready!"
  
  # Create K3s health check script
  - |
    cat > /usr/local/bin/k3s-health-check.sh << 'EOF'
    #!/bin/bash
    # K3s Health Check Script
    
    KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
    
    echo "=== K3s Health Check ==="
    echo "Timestamp: $(date)"
    
    # Check K3s service status
    echo "K3s service status:"
    systemctl is-active k3s || exit 1
    
    # Check node status
    echo "Node status:"
    kubectl get nodes --kubeconfig=$KUBECONFIG || exit 1
    
    # Check system pods
    echo "System pods status:"
    kubectl get pods -n kube-system --kubeconfig=$KUBECONFIG || exit 1
    
    # Check if API server is responsive
    echo "API server connectivity:"
    kubectl cluster-info --kubeconfig=$KUBECONFIG || exit 1
    
    echo "=== Health check completed successfully ==="
    EOF
    
    chmod +x /usr/local/bin/k3s-health-check.sh
  
  # Set up systemd service for K3s health monitoring
  - |
    cat > /etc/systemd/system/k3s-health-monitor.service << 'EOF'
    [Unit]
    Description=K3s Health Monitor
    After=k3s.service
    Requires=k3s.service
    
    [Service]
    Type=oneshot
    ExecStart=/usr/local/bin/k3s-health-check.sh
    User=root
    StandardOutput=journal
    StandardError=journal
    
    [Install]
    WantedBy=multi-user.target
    EOF
    
    systemctl daemon-reload
    systemctl enable k3s-health-monitor.service
  
  # Set up periodic health check timer
  - |
    cat > /etc/systemd/system/k3s-health-monitor.timer << 'EOF'
    [Unit]
    Description=Run K3s Health Check every 5 minutes
    Requires=k3s-health-monitor.service
    
    [Timer]
    OnBootSec=5min
    OnUnitActiveSec=5min
    
    [Install]
    WantedBy=timers.target
    EOF
    
    systemctl daemon-reload
    systemctl enable k3s-health-monitor.timer
    systemctl start k3s-health-monitor.timer

# Write additional configuration files
write_files:
  - path: /etc/systemd/resolved.conf.d/dns_servers.conf
    content: |
      [Resolve]
      DNS=${dns_server_1} ${dns_server_2}
      FallbackDNS=8.8.8.8 1.1.1.1
    permissions: '0644'
  
  - path: /etc/ssh/sshd_config.d/99-custom.conf
    content: |
      PasswordAuthentication no
      PubkeyAuthentication yes
      PermitRootLogin no
      Port 22
    permissions: '0644'
  
  - path: /etc/rancher/k3s/config.yaml
    content: |
      # K3s server configuration
      token: "${k3s_token}"
      node-name: "${k3s_node_name}"
      cluster-init: true
      disable: [${k3s_disable_components}]
      cluster-cidr: "${k3s_cluster_cidr}"
      service-cidr: "${k3s_service_cidr}"
      write-kubeconfig-mode: "0644"
      kube-apiserver-arg:
        - "enable-admission-plugins=NodeRestriction"
      kube-controller-manager-arg:
        - "bind-address=0.0.0.0"
      kube-scheduler-arg:
        - "bind-address=0.0.0.0"
    permissions: '0600'
    owner: root:root
  
  - path: /home/${username}/.bashrc_custom
    content: |
      # Custom aliases and functions
      alias ll='ls -alF'
      alias la='ls -A'
      alias l='ls -CF'
      alias k='kubectl'
      
      # K3s environment
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      
      # Docker aliases
      alias dps='docker ps'
      alias dimg='docker images'
      alias dlog='docker logs'
      
      # K3s aliases and functions
      alias k3s-status='systemctl status k3s'
      alias k3s-logs='journalctl -u k3s -f'
      alias k3s-health='/usr/local/bin/k3s-health-check.sh'
      
      # Function to get cluster info
      k3s-info() {
        echo "=== K3s Cluster Information ==="
        kubectl cluster-info --kubeconfig=/etc/rancher/k3s/k3s.yaml
        echo ""
        echo "=== Nodes ==="
        kubectl get nodes --kubeconfig=/etc/rancher/k3s/k3s.yaml
        echo ""
        echo "=== System Pods ==="
        kubectl get pods -n kube-system --kubeconfig=/etc/rancher/k3s/k3s.yaml
      }
    permissions: '0644'
    owner: ${username}:${username}

# Final commands to run after all other cloud-init modules
final_message: |
  Cloud-init setup completed successfully!
  VM: ${hostname}
  User: ${username}
  SSH access configured with public key authentication
  K3s cluster installed and configured
  
  K3s Configuration:
  - Version: ${k3s_version}
  - Node Name: ${k3s_node_name}
  - Cluster CIDR: ${k3s_cluster_cidr}
  - Service CIDR: ${k3s_service_cidr}
  - Disabled Components: ${k3s_disable_components}
  
  Access Information:
  1. SSH into the VM: ssh ${username}@${vm_ip}
  2. Check K3s status: sudo systemctl status k3s
  3. View cluster info: kubectl cluster-info
  4. Run health check: k3s-health
  5. Kubeconfig location: /etc/rancher/k3s/k3s.yaml
  
  The K3s cluster is ready for workload deployment!

# Power state management
power_state:
  delay: "+1"
  mode: reboot
  message: "Rebooting after cloud-init setup"
  condition: True