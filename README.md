# Jimmy's Home Server

A comprehensive Docker-based home server setup providing self-hosted applications, infrastructure services, and automation tools. This repository contains containerized services for personal cloud storage, development tools, monitoring, networking, and entertainment.

## 🏗️ Architecture Overview

The home server is organized into two main categories:

- **`app/`** - Application services (web apps, tools, games)
- **`infra/`** - Infrastructure services (CI/CD, automation, version control)

All services are containerized using Docker Compose for easy deployment and management.

## 🚀 Core Services

### Infrastructure & DevOps
- **[Gitea](infra/gitea/)** - Self-hosted Git service with Actions CI/CD
- **[Jenkins](app/jenkins/)** - Automation server for CI/CD pipelines
- **[Ansible Semaphore](app/semaphore/)** - Web UI for Ansible automation
- **[Portainer](https://portainer.jimmylab.duckdns.org)** - Docker container management
- **[Prometheus](app/prometheus/)** - Metrics collection and monitoring
- **[Grafana](app/grafana/)** - Data visualization and dashboards

### Applications & Tools
- **[Homer](app/homer/)** - Dashboard for all services
- **[OpenWebUI](app/openwebui/)** - AI chat interface with MCP integration
- **[n8n](app/n8n/)** - Workflow automation platform
- **[Uptime Kuma](app/uptime_kuma/)** - Service monitoring and alerting
- **[Nextcloud](https://jimmyviva.tplinkdns.com)** - Personal cloud storage
- **[Home Assistant](https://homeassistant.jimmylab.duckdns.org)** - Smart home automation
- **[Obsidian Sync](app/obsidian-sync/)** - Note synchronization service

### Network & Security
- **[AdGuard Home](app/adguard/)** - DNS-based ad blocking
- **[Nginx Proxy Manager](app/nginx-manager/)** - Reverse proxy with SSL
- **[OpenVPN](app/open_vpn/)** - VPN server for secure remote access

### Entertainment & Gaming
- **[Minecraft Servers](app/minecraft_season4/)** - Multiple Minecraft server instances
- **[OwnTone](http://192.168.68.128:3689/)** - Music streaming server

### Data & Analytics
- **[FinMind](app/finmind/)** - Financial data visualization platform
- **[MySQL](app/mysql8/)** - Database server

## 🌐 Access Dashboard

The [Homer dashboard](app/homer/) provides a centralized interface to access all services:

**Local Access**: `http://localhost:8080` (when Homer is running)

**Public Access**: Available through configured domain names (*.jimmylab.duckdns.org)

## 🛠️ Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Sufficient disk space for data volumes
- Network ports available (see individual service documentation)

### Basic Setup

1. **Clone the repository**
   ```bash
   git clone https://gitea.jimmylab.duckdns.org/jimmy/home-server.git
   cd home-server
   ```

2. **Start core services**
   ```bash
   # Start the dashboard
   cd app/homer && docker-compose up -d

   # Start infrastructure services
   cd ../infra/gitea && ./start.sh
   cd ../../app/nginx-manager && docker-compose up -d
   ```

3. **Access the dashboard**
   Open `http://localhost:8080` to see all available services

### Service-Specific Setup

Each service directory contains its own README with detailed setup instructions:

- **Gitea**: See [infra/gitea/README.md](infra/gitea/README.md) for Git server setup
- **OpenWebUI**: See [app/openwebui/README.md](app/openwebui/README.md) for AI chat setup
- **AdGuard**: See [app/adguard/readme.md](app/adguard/readme.md) for DNS configuration

## 📁 Directory Structure

```
home-server/
├── app/                    # Application services
│   ├── adguard/           # DNS ad blocking
│   ├── grafana/           # Monitoring dashboards
│   ├── homer/             # Service dashboard
│   ├── jenkins/           # CI/CD automation
│   ├── minecraft_*/       # Game servers
│   ├── openwebui/         # AI chat interface
│   ├── nginx-manager/     # Reverse proxy
│   └── ...
├── infra/                 # Infrastructure services
│   ├── ansible/           # Automation playbooks
│   ├── gitea/             # Git server with CI/CD
│   └── jenkins/           # CI/CD pipelines
└── README.md              # This file
```

## 🔧 Management

### Common Commands

```bash
# Start all services in a directory
docker-compose up -d

# View service logs
docker-compose logs -f [service-name]

# Stop services
docker-compose down

# Update service images
docker-compose pull && docker-compose up -d
```

### Automation

The repository includes Ansible playbooks for automated deployment:

```bash
cd infra/ansible
ansible-playbook -i inventory deploy-homer-playbook.yml
```

## 🌍 Network Configuration

### Domain Setup
- **Primary Domain**: `jimmylab.duckdns.org`
- **Subdomains**: Each service has its own subdomain (e.g., `grafana.jimmylab.duckdns.org`)

### Port Mapping
- Most services use standard HTTP/HTTPS ports through reverse proxy
- SSH services typically use port 2222
- Direct access ports are documented in each service's README

## 🔒 Security Features

- **SSL/TLS**: Automated certificate management via Nginx Proxy Manager
- **VPN Access**: OpenVPN server for secure remote connections
- **DNS Filtering**: AdGuard Home blocks malicious domains
- **Access Control**: Service-level authentication and authorization
- **Network Isolation**: Docker networks provide service isolation

## 📊 Monitoring & Observability

- **Uptime Monitoring**: Uptime Kuma tracks service availability
- **Metrics Collection**: Prometheus gathers system and application metrics
- **Visualization**: Grafana provides comprehensive dashboards
- **Log Management**: Centralized logging through Docker

## 🎮 Gaming & Entertainment

- **Minecraft**: Multiple server instances for different seasons/modpacks
- **Music Streaming**: OwnTone server for local music library
- **Media Management**: Integration ready for additional media services

## 🤖 AI & Automation

- **OpenWebUI**: Modern chat interface for AI models with MCP tool integration
- **n8n**: Visual workflow automation for connecting services
- **Home Assistant**: Smart home device automation and control

## 🔄 Backup & Recovery

- **Data Persistence**: All critical data stored in Docker volumes
- **Configuration Management**: Infrastructure as Code approach
- **Version Control**: All configurations tracked in Git

## 📚 Documentation

Each service includes detailed documentation:
- Setup and configuration instructions
- Troubleshooting guides
- Usage examples
- Security considerations

## 🤝 Contributing

This is a personal home server setup, but feel free to:
- Use configurations as reference for your own setup
- Submit issues for bugs or improvements
- Suggest new services or optimizations

## 📄 License

This project is for personal use. Individual services maintain their own licenses.

---

**Dashboard Access**: [Homer Dashboard](http://localhost:8080) | **Git Repository**: [Gitea](https://gitea.jimmylab.duckdns.org/jimmy/home-server)
