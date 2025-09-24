#!/bin/bash

# K3s Installation Script for Linux
# Based on SUSE Rancher documentation
# This script installs k3s and prepares it for Rancher deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
    fi
}

# Check system requirements
check_requirements() {
    log "Checking system requirements..."
    
    # Check if curl is installed
    if ! command -v curl >/dev/null 2>&1; then
        error "curl is required but not installed. Please install curl first."
    fi
    
    # Check available memory (k3s requires at least 512MB)
    available_mem=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [ "$available_mem" -lt 512 ]; then
        warn "Available memory is less than 512MB. k3s may not run properly."
    fi
    
    # Check disk space (at least 1GB free)
    available_disk=$(df / | awk 'NR==2{print $4}')
    if [ "$available_disk" -lt 1048576 ]; then
        warn "Available disk space is less than 1GB. Consider freeing up space."
    fi
    
    log "System requirements check completed."
}

# Install k3s
install_k3s() {
    log "Installing k3s..."
    
    # Set k3s version (you can modify this to use a specific version)
    K3S_VERSION=${K3S_VERSION:-""}
    
    # Install k3s with cluster-init for embedded etcd
    if [ -n "$K3S_VERSION" ]; then
        log "Installing k3s version: $K3S_VERSION"
        curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" sh -s - server --cluster-init --write-kubeconfig-mode 644
    else
        log "Installing latest k3s version"
        curl -sfL https://get.k3s.io | sh -s - server --cluster-init --write-kubeconfig-mode 644
    fi
    
    # Wait for k3s to be ready
    log "Waiting for k3s to be ready..."
    timeout=300
    while [ $timeout -gt 0 ]; do
        if sudo k3s kubectl get nodes >/dev/null 2>&1; then
            break
        fi
        sleep 5
        timeout=$((timeout - 5))
    done
    
    if [ $timeout -le 0 ]; then
        error "k3s failed to start within 5 minutes"
    fi
    
    log "k3s installation completed successfully!"
}

# Configure kubectl access
configure_kubectl() {
    log "Configuring kubectl access..."
    
    # Create .kube directory if it doesn't exist
    mkdir -p ~/.kube
    
    # Copy k3s kubeconfig to user's .kube directory
    sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
    sudo chown $(id -u):$(id -g) ~/.kube/config
    chmod 600 ~/.kube/config
    
    # Set KUBECONFIG environment variable
    echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc
    export KUBECONFIG=~/.kube/config
    
    log "kubectl configuration completed."
}

# Install Helm (required for Rancher)
install_helm() {
    log "Installing Helm..."

    if command -v helm >/dev/null 2>&1; then
        log "Helm is already installed. Version: $(helm version --short)"
        return
    fi
    
    # Install Helm
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    log "Helm installation completed."
}

# Add Rancher Helm repository
add_rancher_repo() {
    log "Adding Rancher Helm repository..."
    
    # Add the Rancher repository
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo update
    
    log "Rancher Helm repository added successfully."
}

# Install cert-manager (required for Rancher)
install_cert_manager() {
    log "Installing cert-manager..."
    
    # Add the Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    
    # Create cert-manager namespace
    kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
    
    # Install cert-manager
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --set installCRDs=true \
        --version v1.13.0
    
    # Wait for cert-manager to be ready
    log "Waiting for cert-manager to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s
    
    log "cert-manager installation completed."
}

# Create cattle-system namespace for Rancher
create_rancher_namespace() {
    log "Creating cattle-system namespace..."
    kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -
    log "cattle-system namespace created."
}

# Display cluster information
display_cluster_info() {
    log "Displaying cluster information..."
    
    echo -e "\n${BLUE}=== K3s Cluster Information ===${NC}"
    echo -e "${BLUE}Nodes:${NC}"
    kubectl get nodes -o wide
    
    echo -e "\n${BLUE}System Pods:${NC}"
    kubectl get pods -A
    
    echo -e "\n${BLUE}Cluster Info:${NC}"
    kubectl cluster-info
    
    echo -e "\n${BLUE}K3s Service Status:${NC}"
    sudo systemctl status k3s --no-pager
}

# Display next steps
display_next_steps() {
    echo -e "\n${GREEN}=== Installation Complete! ===${NC}"
    echo -e "${GREEN}k3s has been successfully installed and configured.${NC}\n"
    
    echo -e "${BLUE}Next steps to install Rancher:${NC}"
    echo -e "1. Install Rancher using the provided script:"
    echo -e "   ${YELLOW}./install-rancher.sh --hostname rancher.my.org --password admin123456789${NC}"
    echo -e ""
    echo -e "2. Or install manually using Helm:"
    echo -e "   ${YELLOW}helm install rancher rancher-latest/rancher \\${NC}"
    echo -e "   ${YELLOW}  --namespace cattle-system \\${NC}"
    echo -e "   ${YELLOW}  --set hostname=rancher.my.org \\${NC}"
    echo -e "   ${YELLOW}  --set bootstrapPassword=admin123456789${NC}"
    echo -e ""
    echo -e "3. Wait for Rancher to be ready:"
    echo -e "   ${YELLOW}kubectl -n cattle-system rollout status deploy/rancher${NC}"
    echo -e ""
    echo -e "4. Access Rancher UI:"
    echo -e "   ${YELLOW}kubectl -n cattle-system get ingress${NC}"
    echo -e ""
    echo -e "${BLUE}Useful commands:${NC}"
    echo -e "- Check k3s status: ${YELLOW}sudo systemctl status k3s${NC}"
    echo -e "- View k3s logs: ${YELLOW}sudo journalctl -u k3s -f${NC}"
    echo -e "- Restart k3s: ${YELLOW}sudo systemctl restart k3s${NC}"
    echo -e "- Uninstall k3s: ${YELLOW}/usr/local/bin/k3s-uninstall.sh${NC}"
    echo -e ""
    echo -e "${GREEN}Configuration files:${NC}"
    echo -e "- k3s config: ${YELLOW}/etc/rancher/k3s/k3s.yaml${NC}"
    echo -e "- kubectl config: ${YELLOW}~/.kube/config${NC}"
}

# Main installation function
main() {
    echo -e "${BLUE}=== K3s Installation Script ===${NC}"
    echo -e "${BLUE}This script will install k3s and prepare it for Rancher deployment${NC}\n"
    
    # Initialize variables
    SKIP_RANCHER_PREP=false
    SKIP_CERT_MANAGER=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --version)
                K3S_VERSION="$2"
                shift 2
                ;;
            --skip-rancher-prep)
                SKIP_RANCHER_PREP=true
                shift
                ;;
            --skip-cert-manager)
                SKIP_CERT_MANAGER=true
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  --version VERSION     Install specific k3s version"
                echo "  --skip-rancher-prep   Skip Rancher preparation steps"
                echo "  --skip-cert-manager   Skip cert-manager installation (only applies if rancher-prep is not skipped)"
                echo "  --help               Show this help message"
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Debug output to show parsed flags
    log "Configuration:"
    log "  K3S_VERSION: ${K3S_VERSION:-latest}"
    log "  SKIP_RANCHER_PREP: $SKIP_RANCHER_PREP"
    log "  SKIP_CERT_MANAGER: $SKIP_CERT_MANAGER"
    echo ""
    
    # Run installation steps
    check_root
    check_requirements
    install_k3s
    configure_kubectl
    
    if [ "$SKIP_RANCHER_PREP" = "true" ]; then
        log "Skipping Rancher preparation steps as requested."
    else
        install_helm
        add_rancher_repo
        if [ "$SKIP_CERT_MANAGER" = "true" ]; then
            log "Skipping cert-manager installation as requested."
        else
            install_cert_manager
        fi
        create_rancher_namespace
    fi
    
    display_cluster_info
    display_next_steps
    
    log "k3s installation script completed successfully!"
}

# Run main function
main "$@"
