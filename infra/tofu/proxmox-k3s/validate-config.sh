#!/bin/bash

# Proxmox K3s Terraform Configuration Validator
# This script validates your terraform.tfvars configuration before deployment

set -e

echo "🔍 Proxmox K3s Configuration Validator"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
CHECKS=0

# Helper functions
error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
    ERRORS=$((ERRORS + 1))
}

warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
    WARNINGS=$((WARNINGS + 1))
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_count() {
    CHECKS=$((CHECKS + 1))
}

# Check if terraform.tfvars exists
echo
echo "📁 Checking configuration files..."
check_count

if [ ! -f "terraform.tfvars" ]; then
    error "terraform.tfvars file not found"
    info "Copy terraform.tfvars.example to terraform.tfvars and customize it"
    exit 1
else
    success "terraform.tfvars file found"
fi

# Check if required tools are available
echo
echo "🔧 Checking required tools..."

# Check for SSH
check_count
if command -v ssh >/dev/null 2>&1; then
    success "SSH client found"
else
    error "SSH client not found. Please install OpenSSH client."
fi

# Check for SCP
check_count
if command -v scp >/dev/null 2>&1; then
    success "SCP found"
else
    error "SCP not found. Please install OpenSSH client with SCP support."
fi

# Check for curl (optional but recommended)
check_count
if command -v curl >/dev/null 2>&1; then
    success "curl found (for API validation)"
else
    warning "curl not found. API validation will be limited."
fi

# Parse terraform.tfvars for basic validation
echo
echo "📋 Validating configuration values..."

# Function to extract value from terraform.tfvars
get_tfvar() {
    local var_name="$1"
    local var_path="$2"
    
    if [ -n "$var_path" ]; then
        # For nested variables like proxmox_config.endpoint
        grep -E "^\s*${var_name}\s*=" terraform.tfvars | head -1 | sed 's/.*{//' | grep -E "^\s*${var_path}\s*=" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//'
    else
        # For simple variables
        grep -E "^\s*${var_name}\s*=" terraform.tfvars | head -1 | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//'
    fi
}

# Check Proxmox configuration
check_count
proxmox_endpoint=$(grep -A 10 "proxmox_config\s*=" terraform.tfvars | grep "endpoint" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$proxmox_endpoint" ]; then
    if [[ "$proxmox_endpoint" =~ ^https?:// ]]; then
        success "Proxmox endpoint format is valid"
        
        # Test connectivity if possible
        if command -v curl >/dev/null 2>&1; then
            proxmox_host=$(echo "$proxmox_endpoint" | sed 's|https\?://||' | sed 's|/.*||' | sed 's|:.*||')
            proxmox_port=$(echo "$proxmox_endpoint" | grep -o ':[0-9]*' | sed 's/://' || echo "8006")
            
            if curl -s --connect-timeout 5 -k "$proxmox_endpoint" >/dev/null 2>&1; then
                success "Proxmox endpoint is reachable"
            else
                warning "Cannot reach Proxmox endpoint. Check network connectivity."
            fi
        fi
    else
        error "Proxmox endpoint must start with http:// or https://"
    fi
else
    error "Proxmox endpoint not found in configuration"
fi

# Check VM configuration
check_count
vm_name=$(grep -A 10 "vm_config\s*=" terraform.tfvars | grep "name" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$vm_name" ]; then
    if [[ "$vm_name" =~ ^[a-zA-Z0-9-]+$ ]]; then
        success "VM name format is valid"
        
        # Check for reserved names
        reserved_names="localhost router gateway dns dhcp proxy"
        for reserved in $reserved_names; do
            if [ "$vm_name" = "$reserved" ]; then
                error "VM name '$vm_name' conflicts with reserved hostname"
                break
            fi
        done
    else
        error "VM name must contain only alphanumeric characters and hyphens"
    fi
else
    error "VM name not found in configuration"
fi

# Check CPU and memory configuration
check_count
vm_cores=$(grep -A 10 "vm_config\s*=" terraform.tfvars | grep "cores" | sed 's/.*=\s*//' | sed 's/[",].*$//' || echo "")
vm_memory=$(grep -A 10 "vm_config\s*=" terraform.tfvars | grep "memory" | sed 's/.*=\s*//' | sed 's/[",].*$//' || echo "")

if [ -n "$vm_cores" ] && [ -n "$vm_memory" ]; then
    if [ "$vm_cores" -ge 1 ] && [ "$vm_cores" -le 32 ]; then
        success "VM CPU cores ($vm_cores) are in valid range"
    else
        error "VM cores must be between 1 and 32"
    fi
    
    if [ "$vm_memory" -ge 512 ] && [ "$vm_memory" -le 32768 ]; then
        success "VM memory ($vm_memory MB) is in valid range"
        
        # Performance recommendations
        if [ "$vm_cores" -gt 4 ] && [ "$vm_memory" -lt 4096 ]; then
            warning "High CPU count ($vm_cores) with low memory ($vm_memory MB) may cause performance issues"
        fi
    else
        error "VM memory must be between 512 MB and 32 GB"
    fi
fi

# Check disk size
check_count
vm_disk=$(grep -A 10 "vm_config\s*=" terraform.tfvars | grep "disk_size" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$vm_disk" ]; then
    if [[ "$vm_disk" =~ ^[0-9]+[GM]$ ]]; then
        success "VM disk size format is valid"
        
        # Extract number and unit
        disk_num=$(echo "$vm_disk" | sed 's/[GM]$//')
        disk_unit=$(echo "$vm_disk" | sed 's/^[0-9]*//')
        
        # Convert to GB for comparison
        if [ "$disk_unit" = "G" ]; then
            disk_gb=$disk_num
        else
            disk_gb=$((disk_num / 1024))
        fi
        
        if [ "$disk_gb" -lt 10 ]; then
            warning "Disk size ($vm_disk) may be insufficient for K3s and container images (recommend 20G+)"
        fi
    else
        error "Disk size must be in format like '20G' or '2048M'"
    fi
else
    error "VM disk size not found in configuration"
fi

# Check SSH configuration
echo
echo "🔐 Validating SSH configuration..."

check_count
ssh_public_key=$(grep -A 5 "ssh_config\s*=" terraform.tfvars | grep "public_key" | sed 's/.*=\s*//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$ssh_public_key" ]; then
    if [[ "$ssh_public_key" =~ ^ssh-(rsa|ed25519|ecdsa) ]]; then
        success "SSH public key format appears valid"
        
        # Try to validate with ssh-keygen if available
        if command -v ssh-keygen >/dev/null 2>&1; then
            if echo "$ssh_public_key" | ssh-keygen -l -f - >/dev/null 2>&1; then
                success "SSH public key is valid"
            else
                error "SSH public key failed validation"
            fi
        fi
    else
        error "SSH public key must be in OpenSSH format (ssh-rsa, ssh-ed25519, or ssh-ecdsa)"
    fi
else
    error "SSH public key not found in configuration"
fi

# Check private key file
check_count
ssh_private_key=$(grep -A 5 "ssh_config\s*=" terraform.tfvars | grep "private_key_path" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$ssh_private_key" ]; then
    # Expand tilde
    ssh_private_key_expanded="${ssh_private_key/#\~/$HOME}"
    
    if [ -f "$ssh_private_key_expanded" ]; then
        success "SSH private key file exists"
        
        # Check permissions
        key_perms=$(stat -c "%a" "$ssh_private_key_expanded" 2>/dev/null || stat -f "%A" "$ssh_private_key_expanded" 2>/dev/null || echo "unknown")
        if [ "$key_perms" = "600" ] || [ "$key_perms" = "400" ]; then
            success "SSH private key permissions are secure ($key_perms)"
        else
            warning "SSH private key permissions are $key_perms, should be 600 or 400"
            info "Run: chmod 600 $ssh_private_key_expanded"
        fi
    else
        error "SSH private key file not found: $ssh_private_key_expanded"
    fi
else
    warning "SSH private key path not specified, using default ~/.ssh/id_rsa"
fi

# Check K3s configuration
echo
echo "🚀 Validating K3s configuration..."

check_count
k3s_token=$(grep -A 10 "k3s_config\s*=" terraform.tfvars | grep "token" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$k3s_token" ]; then
    token_length=${#k3s_token}
    if [ "$token_length" -ge 16 ]; then
        if [ "$token_length" -ge 32 ]; then
            success "K3s token length is secure ($token_length characters)"
        else
            warning "K3s token is $token_length characters, recommend 32+ for better security"
        fi
    else
        error "K3s token must be at least 16 characters long"
    fi
else
    error "K3s token not found in configuration"
fi

# Check K3s version
check_count
k3s_version=$(grep -A 10 "k3s_config\s*=" terraform.tfvars | grep "version" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$k3s_version" ]; then
    if [ "$k3s_version" = "latest" ] || [[ "$k3s_version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+ ]]; then
        success "K3s version format is valid ($k3s_version)"
    else
        error "K3s version must be 'latest' or semantic version like 'v1.28.2+k3s1'"
    fi
else
    warning "K3s version not specified, will use 'latest'"
fi

# Check network configuration
echo
echo "🌐 Validating network configuration..."

check_count
ip_address=$(grep -A 10 "network_config\s*=" terraform.tfvars | grep "ip_address" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$ip_address" ]; then
    if [ "$ip_address" = "dhcp" ]; then
        success "Using DHCP for IP assignment"
        info "Ensure DHCP server is available on the network"
    elif [[ "$ip_address" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        success "Static IP format is valid ($ip_address)"
        
        # Check if gateway is specified for static IP
        gateway=$(grep -A 10 "network_config\s*=" terraform.tfvars | grep "gateway" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")
        if [ -n "$gateway" ] && [ "$gateway" != '""' ]; then
            success "Gateway specified for static IP ($gateway)"
        else
            warning "Gateway not specified for static IP configuration"
        fi
    else
        error "IP address must be 'dhcp' or valid CIDR notation (e.g., '192.168.1.100/24')"
    fi
else
    error "IP address configuration not found"
fi

# Check CIDR blocks for conflicts
check_count
cluster_cidr=$(grep -A 10 "k3s_config\s*=" terraform.tfvars | grep "cluster_cidr" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")
service_cidr=$(grep -A 10 "k3s_config\s*=" terraform.tfvars | grep "service_cidr" | sed 's/.*=\s*//' | sed 's/[",].*$//' | sed 's/^"//' | sed 's/"$//' || echo "")

if [ -n "$cluster_cidr" ] && [ -n "$service_cidr" ]; then
    # Basic overlap check (first two octets)
    cluster_net=$(echo "$cluster_cidr" | cut -d'/' -f1 | cut -d'.' -f1-2)
    service_net=$(echo "$service_cidr" | cut -d'/' -f1 | cut -d'.' -f1-2)
    
    if [ "$cluster_net" = "$service_net" ]; then
        warning "Cluster CIDR ($cluster_cidr) and Service CIDR ($service_cidr) may overlap"
    else
        success "Cluster and Service CIDR blocks appear to be separate"
    fi
    
    # Check for common network conflicts
    common_networks="192.168.1 192.168.0 10.0.0 172.16.0"
    for network in $common_networks; do
        if [ "$cluster_net" = "$network" ] || [ "$service_net" = "$network" ]; then
            warning "K3s CIDR ranges may conflict with common network $network.0/24"
        fi
    done
fi

# Summary
echo
echo "📊 Validation Summary"
echo "===================="
echo -e "Total checks: ${BLUE}$CHECKS${NC}"
echo -e "Errors: ${RED}$ERRORS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"

if [ $ERRORS -eq 0 ]; then
    echo
    success "Configuration validation passed!"
    if [ $WARNINGS -gt 0 ]; then
        info "Please review the warnings above before deployment"
    fi
    echo
    info "Next steps:"
    echo "  1. Run: terraform init"
    echo "  2. Run: terraform plan"
    echo "  3. Run: terraform apply"
else
    echo
    error "Configuration validation failed with $ERRORS error(s)"
    info "Please fix the errors above before deployment"
    exit 1
fi

echo
echo "🚀 Ready for deployment!"