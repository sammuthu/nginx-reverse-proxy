# Nginx Reverse Proxy Configuration Manager

Centralized management for all nginx reverse proxy configurations and port assignments across development projects.

## Overview

This project manages:
- Nginx reverse proxy configurations for all local development services
- Port allocation tracking to prevent conflicts
- Service health monitoring
- Automated nginx configuration updates

## Quick Start

```bash
# View all services and their ports
./scripts/list-services.sh

# Add a new service
./scripts/add-service.sh <service-name> <port> <domain>

# Update nginx configuration
./scripts/update-nginx.sh

# Check service health
./scripts/health-check.sh
```

## Current Port Allocations

| Port | Service | Domain | Status |
|------|---------|--------|--------|
| 80 | Nginx Reverse Proxy | - | Active |
| 3355 | Sammuthu Dev Site | sammuthu.dev | Configured |
| 5000 | Onyx Web Interface (Docker) | onyx.local | Docker |
| 5001 | MinIO Console | minio.local | Docker |
| 5008 | Onyx API Server | api.onyx.local | Docker |
| 5009 | MinIO API | - | Docker |
| 5019 | Vespa Index | vespa.local | Docker |
| 5379 | Redis Cache | - | Docker |
| 5433 | PostgreSQL | - | Docker |
| 7777 | CosmicBoard | cosmic.board | Active |
| 8082 | CosmicBoard Mobile (Expo Web) | m.cosmic.board | Active |
| 8088 | Segment Loop Master Frontend | loopify.sam, loopify.dev | Active |
| 9001 | Segment Loop Master Backend | - | Active |
| 9393 | Prism AI | prism.ai | Configured |
| 11434 | Ollama API | - | System Service |

## Directory Structure

```
nginx-reverse-proxy/
├── config/
│   ├── nginx.conf           # Main nginx configuration (symlinked)
│   ├── sites-available/     # Available site configurations
│   └── sites-enabled/       # Enabled site configurations
├── scripts/
│   ├── add-service.sh       # Add new service
│   ├── list-services.sh     # List all services
│   ├── update-nginx.sh      # Update nginx configuration
│   ├── health-check.sh      # Check service health
│   └── port-scanner.py      # Find available ports
├── docs/
│   ├── port-registry.json   # Port allocation registry
│   └── service-details.md   # Detailed service documentation
└── README.md
```

## Service Details

### Production Services

**CosmicBoard** (Port 7777)
- Next.js task management application
- Domain: cosmic.board
- Start: `cd ~/Projects/cosmicboard && npm run dev`

**CosmicBoard Mobile** (Port 8082)
- React Native (Expo) mobile application - Web version
- Domain: m.cosmic.board
- Start: `cd ~/Projects/cosmicboard-mobile && npx expo start --web --port 8082`
- Access web version at http://m.cosmic.board
- Note: Web version requires react-native-web installed

**Segment Loop Master** (Ports 8088, 9001)
- Frontend: Python HTTP server on 8088
- Backend: FastAPI on 9001
- Domains: loopify.sam, loopify.dev
- Start: `cd ~/Projects/segment-loop-master && ./local-start.sh`

**Sammuthu Dev Site** (Port 3355)
- Personal portfolio site
- Domain: sammuthu.dev
- Start: `cd ~/Projects/sammuthu-dev-site && ./start.sh`

**Prism AI** (Port 9393)
- AI service interface
- Domain: prism.ai
- Configuration only (service not implemented)

### Docker Services (Onyx)

**Onyx Stack** (Multiple Ports)
- Web UI: 5000
- API: 5008
- MinIO: 5001 (console), 5009 (API)
- Vespa: 5019
- Redis: 5379
- PostgreSQL: 5433
- Start: `cd ~/Projects/onyx-custom-config && docker-compose up`

### System Services

**Ollama** (Port 11434)
- Local LLM API service
- Managed by system (brew services)

## Nginx Configuration

The main nginx configuration is located at:
- Actual: `/Users/sammuthu/zScripts/bin/reverse-proxy/nginx.conf`
- Symlinked to: `/opt/homebrew/etc/nginx/nginx.conf`

## Managing Services

### Adding a New Service

1. Check available ports:
```bash
./scripts/port-scanner.py --range 3000-10000
```

2. Add service configuration:
```bash
./scripts/add-service.sh myapp 3000 myapp.local
```

3. Update /etc/hosts:
```bash
sudo ./scripts/update-hosts.sh myapp.local
```

4. Restart nginx:
```bash
brew services restart nginx
```

### Checking Service Status

```bash
# Check all services
./scripts/health-check.sh

# Check specific port
lsof -i :7777

# Check nginx status
brew services list | grep nginx
```

## Troubleshooting

### Port Conflicts
- Use `./scripts/port-scanner.py` to find available ports
- Check `docs/port-registry.json` for allocated ports

### DNS Resolution
- Ensure /etc/hosts has correct entries
- Flush DNS: `sudo dscacheutil -flushcache`

### Nginx Issues
- Check config: `nginx -t`
- View logs: `tail -f /opt/homebrew/var/log/nginx/error.log`
- Restart: `brew services restart nginx`