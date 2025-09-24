# Project Structure

## Directory Organization

The repository follows a clear separation between applications and infrastructure:

```
home-server/
├── app/                    # Application services
├── infra/                  # Infrastructure & automation
├── .kiro/                  # Kiro AI assistant configuration
├── README.md               # Project documentation
└── ssh-agent.sh           # SSH setup script
```

## Application Services (`app/`)

Each service has its own directory with standardized structure:

```
app/[service-name]/
├── docker-compose.yml      # Service definition (required)
├── .env                   # Environment variables (optional)
├── data/                  # Persistent data volume
├── config/                # Configuration files
└── README.md              # Service-specific documentation
```

### Service Categories
- **Infrastructure**: jenkins, rancher, nginx-manager, mysql8
- **Monitoring**: grafana, prometheus, uptime_kuma
- **Network**: adguard, open_vpn
- **Productivity**: homer (dashboard), n8n, obsidian-sync, openwebui
- **Entertainment**: minecraft_season*, aio_imaginary
- **Development**: semaphore
- **Data**: finmind

## Infrastructure Services (`infra/`)

Infrastructure automation and tooling:

```
infra/
├── ansible/               # Automation playbooks
│   ├── roles/            # Reusable Ansible roles
│   ├── group_vars/       # Variable definitions
│   ├── inventory         # Host inventory
│   └── *.yml            # Deployment playbooks
├── gitea/                # Git server with CI/CD
├── helm/                 # Kubernetes charts
├── jenkins/              # CI/CD pipeline definitions
├── scripts/              # Installation scripts (K3s, Rancher)
└── terraform/            # Infrastructure as Code
```

## Naming Conventions

- **Services**: lowercase with hyphens (nginx-manager, uptime_kuma)
- **Minecraft servers**: versioned by season (minecraft_season4, minecraft_season5)
- **Configuration files**: Standard names (docker-compose.yml, .env, README.md)
- **Data directories**: Always named `data/` for persistence
- **Playbooks**: Descriptive with action prefix (deploy-*, backup-*)

## File Patterns

- **docker-compose.yml**: Required in every service directory
- **.env files**: Used for sensitive configuration
- **README.md**: Service-specific setup and usage instructions
- **start.sh**: Custom startup scripts where needed
- **Dockerfiles**: Custom image builds (rare, prefer official images)

## Volume Management

- **Local paths**: Absolute paths to `/home/jimmy/home-server/`
- **Data persistence**: `./data/` directories for stateful services
- **Configuration**: `./config/` for service configurations
- **Shared resources**: Cross-service dependencies minimized

## Port Allocation

- **Reverse proxy**: Most services behind Nginx Proxy Manager
- **Direct access**: Specific ports for SSH (2222), databases, etc.
- **Development**: Port 8080 for Homer dashboard
- **Monitoring**: Standard ports (3000 for Grafana, etc.)

## Documentation Standards

- Each service directory should contain setup instructions
- Environment variable documentation in README files
- Network and security considerations documented
- Backup and recovery procedures where applicable