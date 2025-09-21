# Gitea with Actions Runner

This directory contains the setup for running Gitea with Actions Runner using Docker Compose.

## Usage

### Start all services (Gitea + Runner)
```bash
./start.sh
```

### Restart only the Actions Runner (keep Gitea running)
```bash
./start.sh --restart-runner
```

### Other options
```bash
./start.sh --clean      # Clean restart with image cleanup
./start.sh --no-cache   # Force pull latest images
```

## New Feature: Restart Runner Only

The `--restart-runner` option allows you to restart only the Actions Runner service while keeping the Gitea server running. This is useful when:

- You need to update the runner configuration
- The runner has stopped working but Gitea is fine
- You want to apply new environment variables to the runner
- You need to troubleshoot runner issues without affecting Gitea uptime

### How it works

1. **Checks prerequisites**: Verifies Docker is running and docker-compose.yml exists
2. **Validates Gitea status**: Ensures Gitea server is currently running
3. **Stops runner only**: Uses `docker-compose stop runner` and `docker-compose rm -f runner`
4. **Restarts runner**: Uses `docker-compose up -d runner` to start only the runner service
5. **Status check**: Verifies the runner reconnects to Gitea successfully

### Error handling

- If Gitea is not running, the script will exit with an error message
- If Docker is not available, the script will exit gracefully
- The script provides clear feedback about the runner's connection status

## Services

- **server**: Gitea server (port 4000 for web, 2222 for SSH)
- **runner**: Gitea Actions Runner that connects to the server

## Configuration

- Create a `.env` file with your `REGISTRATION_TOKEN`
- The runner configuration is in `runner/config.yaml`
- Data is persisted in `./data` and `./config` directories
