# Technology Stack

## Core Technologies
- **Containerization**: Docker & Docker Compose for all services
- **Orchestration**: Kubernetes (K3s) with Rancher management
- **Infrastructure as Code**: Terraform, Ansible, Helm charts
- **Version Control**: Gitea with Actions CI/CD
- **Reverse Proxy**: Nginx Proxy Manager with SSL automation
- **Monitoring**: Prometheus + Grafana stack
- **Databases**: MySQL 8, service-specific databases

## Development Tools
- **CI/CD**: Jenkins, Gitea Actions
- **Automation**: Ansible Semaphore, n8n workflows
- **Container Management**: Portainer, Rancher
- **AI Integration**: OpenWebUI with MCP (Model Context Protocol)

## Common Commands

### Docker Operations
```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f [service-name]

# Stop services
docker-compose down

# Update images
docker-compose pull && docker-compose up -d
```

### Infrastructure Automation
```bash
# Ansible deployments
cd infra/ansible
ansible-playbook -i inventory deploy-homer-playbook.yml
ansible-playbook -i inventory deploy-prometheus.yml

# Kubernetes management
cd infra/scripts
./install-k3s.sh
./install-rancher.sh --hostname rancher.jimmylab.duckdns.org

# Terraform operations
cd infra/terraform
terraform init
terraform plan
terraform apply
```

### Service Management
```bash
# SSH agent setup
./ssh-agent.sh

# Gitea startup
cd infra/gitea && ./start.sh

# Service-specific startup scripts available in individual directories
```

## Configuration Patterns
- **Environment files**: `.env` files for service configuration
- **Volume mounts**: Persistent data in `./data/` directories
- **Port mapping**: Services use standard ports through reverse proxy
- **SSL certificates**: Automated via Nginx Proxy Manager
- **Domain routing**: Subdomain-based service access