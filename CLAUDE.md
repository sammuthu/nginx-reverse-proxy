# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Essential Commands

### Service Management
```bash
# List all services with status
./scripts/list-services.sh

# Check health of all services  
./scripts/health-check.sh

# Update nginx configuration after changes
./scripts/update-nginx.sh

# Find available ports
./scripts/port-scanner.py --type frontend  # For frontend apps (3000-3999)
./scripts/port-scanner.py --type api       # For API servers (9000-9999)
./scripts/port-scanner.py --check 3000     # Check specific port availability
```

### Nginx Operations
```bash
# Test configuration
nginx -t

# Restart nginx
brew services restart nginx

# View nginx logs
tail -f /opt/homebrew/var/log/nginx/error.log
```

## Architecture Overview

This repository manages centralized nginx reverse proxy configurations for all local development services. The system consists of:

1. **Port Registry** (`docs/port-registry.json`): Central source of truth for all port allocations and service metadata. Services are categorized as:
   - `active`: Currently running services
   - `configured`: Has nginx config but not always running
   - `docker`: Docker-managed services
   - `not_configured`: Planned but not yet configured
   - `system`: System-level services

2. **Nginx Configuration Structure**:
   - Main config: `config/nginx.conf` (symlinked to `/opt/homebrew/etc/nginx/nginx.conf`)
   - Site configs: `config/sites-available/` contains all configurations
   - Active sites: `config/sites-enabled/` contains symlinks to enabled sites
   - Each service gets its own `.conf` file with proxy settings

3. **Service Scripts**: Bash and Python utilities in `scripts/` for:
   - Service discovery and health monitoring
   - Port allocation and conflict detection  
   - Nginx configuration management with automatic backup/rollback

## Key Services and Ports

- **7777**: CosmicBoard (Next.js) - cosmic.board
- **8082**: CosmicBoard Mobile (Expo Web) - m.cosmic.board  
- **8088/9001**: Segment Loop Master (Frontend/Backend) - loopify.sam, loopify.dev
- **5000-5433**: Onyx Docker stack (Web, API, MinIO, Vespa, Redis, PostgreSQL)
- **11434**: Ollama API (system service)

## Development Workflow

When adding a new service:
1. Check port availability using `port-scanner.py`
2. Update `docs/port-registry.json` with service details
3. Create nginx config in `config/sites-available/`
4. Create symlink in `config/sites-enabled/`
5. Run `./scripts/update-nginx.sh` to apply changes
6. Add domain to `/etc/hosts` if using custom domain

When modifying nginx configurations:
1. Edit files in `config/sites-available/`
2. Run `./scripts/update-nginx.sh` (creates backup, tests config, applies changes with rollback on failure)