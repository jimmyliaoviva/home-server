#!/bin/bash

# Rancher Installation Script for K3s
# Based on SUSE Rancher documentation

# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default values
RANCHER_HOSTNAME=""
RANCHER_PASSWORD=""
CERT_MANAGER_VERSION="v1.13.0"
RANCHER_VERSION=""
SKIP_CERT_MANAGER=false

# Logging functions
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

# Show usage
show_usage() {
    echo "Usage: $0 --hostname <hostname> --password <password> [OPTIONS]"
    echo ""
    echo "Required options:"
    echo "  --hostname <hostname>     Hostname for Rancher (e.g., rancher.example.com)"
    echo "  --password <password>     Bootstrap password for Rancher admin"
    echo ""
    echo "Optional options:"
    echo "  --rancher-version <ver>   Specific Rancher version to install"
    echo "  --cert-manager-version <ver>  Cert-manager version (default: v1.13.0)"
    echo "  --skip-cert-manager       Skip cert-manager installation"
    echo "  --help                    Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --hostname rancher.example.com --password mypassword123"
    echo "  $0 --hostname 192.168.1.100.sslip.io --password admin123 --rancher-version 2.7.5"
    echo "  $0 --hostname rancher.example.com --password mypassword123 --skip-cert-manager"
}

# Parse command line arguments
parse_args() {
    while [ $# -gt 0 ]; do
        case $1 in
            --hostname)
                RANCHER_HOSTNAME="$2"
                shift 2
                ;;
            --password)
                RANCHER_PASSWORD="$2"
                shift 2
                ;;
            --rancher-version)
                RANCHER_VERSION="$2"
                shift 2
                ;;
            --cert-manager-version)
                CERT_MANAGER_VERSION="$2"
                shift 2
                ;;
            --skip-cert-manager)
                SKIP_CERT_MANAGER=true
                shift
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done

    # Validate required parameters
    if [ -z "$RANCHER_HOSTNAME" ]; then
        error "Hostname is required. Use --hostname option."
    fi

    if [ -z "$RANCHER_PASSWORD" ]; then
        error "Password is required. Use --password option."
    fi

    # Validate password requirements
    if [ ${#RANCHER_PASSWORD} -lt 10 ]; then
        error "Password must be at least 10 characters long."
    fi
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if kubectl is available
    if ! command -v kubectl >/dev/null 2>&1; then
        error "kubectl is required but not installed."
    fi

    # Check if helm is available
    if ! command -v helm >/dev/null 2>&1; then
        error "helm is required but not installed."
    fi

    # Check if k3s is running
    if ! kubectl get nodes >/dev/null 2>&1; then
        error "k3s cluster is not accessible. Please ensure k3s is installed and running."
    fi

    log "Prerequisites check completed."
}

# Install cert-manager
install_cert_manager() {
    log "Installing cert-manager..."

    # Add Jetstack Helm repository
    helm repo add jetstack https://charts.jetstack.io
    helm repo update

    # Create cert-manager namespace
    kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

    # Install cert-manager CRDs
    kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml

    # Install cert-manager
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager \
        --create-namespace \
        --version ${CERT_MANAGER_VERSION}

    # Wait for cert-manager to be ready
    log "Waiting for cert-manager to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

    log "cert-manager installation completed."
}

# Install Rancher
install_rancher() {
    log "Installing Rancher..."

    # Add Rancher Helm repository (using latest for this example)
    helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
    helm repo update

    # Create cattle-system namespace
    kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -

    # Prepare Helm install command
    HELM_CMD="helm upgrade --install rancher rancher-latest/rancher \
        --namespace cattle-system \
        --set hostname=${RANCHER_HOSTNAME} \
        --set replicas=1 \
        --set bootstrapPassword=${RANCHER_PASSWORD}"

    # Add version if specified
    if [ -n "$RANCHER_VERSION" ]; then
        HELM_CMD="${HELM_CMD} --version ${RANCHER_VERSION}"
    fi

    # Check Kubernetes version for PSP setting
    # Try multiple methods to get Kubernetes version
    K8S_VERSION=""
    
    # Method 1: Try kubectl version --output=json (newer kubectl versions)
    if [ -z "$K8S_VERSION" ]; then
        K8S_VERSION=$(kubectl version --output=json 2>/dev/null | grep -o '"gitVersion":"v[^"]*"' | head -1 | cut -d'"' -f4 | cut -d'v' -f2)
    fi
    
    # Method 2: Try kubectl version --short (older kubectl versions)
    if [ -z "$K8S_VERSION" ]; then
        K8S_VERSION=$(kubectl version --short 2>/dev/null | grep "Server Version" | cut -d' ' -f3 | cut -d'v' -f2)
    fi
    
    # Method 3: Try kubectl get nodes and extract version
    if [ -z "$K8S_VERSION" ]; then
        K8S_VERSION=$(kubectl get nodes -o jsonpath='{.items[0].status.nodeInfo.kubeletVersion}' 2>/dev/null | cut -d'v' -f2)
    fi
    
    # Method 4: Try server version only
    if [ -z "$K8S_VERSION" ]; then
        K8S_VERSION=$(kubectl version -o json 2>/dev/null | grep -A1 '"serverVersion"' | grep '"gitVersion"' | cut -d'"' -f4 | cut -d'v' -f2)
    fi
    
    log "Detected Kubernetes version: $K8S_VERSION"
    
    if [ -n "$K8S_VERSION" ]; then
        K8S_MAJOR=$(echo "$K8S_VERSION" | cut -d'.' -f1)
        K8S_MINOR=$(echo "$K8S_VERSION" | cut -d'.' -f2)

        # Validate that we got numeric values
        if [ -n "$K8S_MAJOR" ] && [ -n "$K8S_MINOR" ] && [ "$K8S_MAJOR" -eq "$K8S_MAJOR" ] 2>/dev/null && [ "$K8S_MINOR" -eq "$K8S_MINOR" ] 2>/dev/null; then
            if [ "$K8S_MAJOR" -eq 1 ] && [ "$K8S_MINOR" -ge 25 ]; then
                HELM_CMD="${HELM_CMD} --set global.cattle.psp.enabled=false"
                log "Kubernetes v1.25+ detected, disabling PSP"
            else
                log "Kubernetes v$K8S_MAJOR.$K8S_MINOR detected, PSP may be available"
            fi
        else
            warn "Could not parse Kubernetes version ($K8S_VERSION), skipping PSP configuration"
        fi
    else
        warn "Could not determine Kubernetes version, skipping PSP configuration"
    fi
    
    if [ "$SKIP_CERT_MANAGER" = "true" ]; then
        HELM_CMD="${HELM_CMD} --set ingress.tls.source=none --set ingress.http.enabled=true --set tls=external"
    fi
    
    log "Helm command: $HELM_CMD"
    # Execute Helm install
    eval $HELM_CMD

    log "Rancher installation initiated."
}

# Wait for Rancher to be ready
wait_for_rancher() {
    log "Waiting for Rancher to be ready..."

    # Wait for deployment to be ready
    kubectl -n cattle-system rollout status deploy/rancher --timeout=600s

    # Wait for all pods to be ready
    kubectl wait --for=condition=ready pod -l app=rancher -n cattle-system --timeout=600s

    log "Rancher is ready!"
}

# Display access information
display_access_info() {
    echo -e "\n${GREEN}=== Rancher Installation Complete! ===${NC}"
    echo -e "${GREEN}Rancher has been successfully installed.${NC}\n"

    echo -e "${BLUE}Access Information:${NC}"
    echo -e "URL: ${YELLOW}https://${RANCHER_HOSTNAME}${NC}"
    echo -e "Username: ${YELLOW}admin${NC}"
    echo -e "Password: ${YELLOW}${RANCHER_PASSWORD}${NC}"

    echo -e "\n${BLUE}Useful Commands:${NC}"
    echo -e "- Check Rancher status: ${YELLOW}kubectl -n cattle-system get pods${NC}"
    echo -e "- View Rancher logs: ${YELLOW}kubectl -n cattle-system logs -l app=rancher${NC}"
    echo -e "- Restart Rancher: ${YELLOW}kubectl -n cattle-system rollout restart deploy/rancher${NC}"
    echo -e "- Get ingress info: ${YELLOW}kubectl -n cattle-system get ingress${NC}"

    echo -e "\n${BLUE}Next Steps:${NC}"
    echo -e "1. Open your browser and navigate to: ${YELLOW}https://${RANCHER_HOSTNAME}${NC}"
    echo -e "2. Accept the self-signed certificate warning"
    echo -e "3. Log in with username 'admin' and the password you provided"
    echo -e "4. Complete the initial setup wizard"
    echo -e "5. Start managing your Kubernetes clusters!"

    echo -e "\n${YELLOW}Note: If using a .sslip.io domain, you may need to add a security exception in your browser.${NC}"
}

# Main function
main() {
    echo -e "${BLUE}=== Rancher Installation Script ===${NC}"
    echo -e "${BLUE}This script will install Rancher on your existing k3s cluster${NC}\n"

    parse_args "$@"
    check_prerequisites
    if [ "$SKIP_CERT_MANAGER" != "true" ]; then
        install_cert_manager
    fi
    install_rancher
    wait_for_rancher
    display_access_info

    log "Rancher installation completed successfully!"
}

# Run main function with all arguments
main "$@"
