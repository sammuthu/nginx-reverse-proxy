#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

REGISTRY_FILE="../docs/port-registry.json"

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}   Service Health Check${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Check nginx status
echo -e "${YELLOW}Checking Nginx...${NC}"
if brew services list | grep nginx | grep -q started; then
    echo -e "  ${GREEN}✓${NC} Nginx is running"
    
    # Test nginx config
    if nginx -t 2>/dev/null; then
        echo -e "  ${GREEN}✓${NC} Nginx configuration is valid"
    else
        echo -e "  ${RED}✗${NC} Nginx configuration has errors"
    fi
else
    echo -e "  ${RED}✗${NC} Nginx is not running"
    echo -e "  ${GRAY}  Run: brew services start nginx${NC}"
fi

echo

# Check MongoDB (for CosmicBoard)
echo -e "${YELLOW}Checking MongoDB...${NC}"
if pgrep -x "mongod" > /dev/null; then
    echo -e "  ${GREEN}✓${NC} MongoDB is running"
else
    echo -e "  ${YELLOW}⚠${NC} MongoDB is not running"
    echo -e "  ${GRAY}  Run: brew services start mongodb-community${NC}"
fi

echo

# Check Ollama
echo -e "${YELLOW}Checking Ollama...${NC}"
if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
    echo -e "  ${GREEN}✓${NC} Ollama API is responding"
else
    echo -e "  ${YELLOW}⚠${NC} Ollama API is not responding"
    echo -e "  ${GRAY}  Run: ollama serve${NC}"
fi

echo

# Check services from registry
echo -e "${YELLOW}Checking Registered Services...${NC}"

# Function to check HTTP service
check_http_service() {
    local port=$1
    local domain=$2
    
    if [ -n "$domain" ] && [ "$domain" != "null" ] && [ "$domain" != "N/A" ]; then
        # Try with domain
        if curl -s -o /dev/null -w "%{http_code}" -m 2 "http://$domain" | grep -q "200\|301\|302"; then
            return 0
        fi
    fi
    
    # Try with localhost
    if curl -s -o /dev/null -w "%{http_code}" -m 2 "http://localhost:$port" | grep -q "200\|301\|302\|404"; then
        return 0
    fi
    
    # Check if port is at least listening
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Parse services and check health
jq -r '.services[] | select(.status == "active" or .status == "configured") | "\(.port)|\(.name)|\(.domain // "N/A")|\(.project_path // "N/A")"' "$REGISTRY_FILE" 2>/dev/null | while IFS='|' read -r port name domain path; do
    if check_http_service "$port" "$domain"; then
        echo -e "  ${GREEN}✓${NC} $name (port $port)"
    else
        echo -e "  ${RED}✗${NC} $name (port $port)"
        if [ "$path" != "N/A" ] && [ -d "$path" ]; then
            echo -e "    ${GRAY}Start with: cd $path && npm run dev${NC}"
        fi
    fi
done

echo

# Check Docker services
echo -e "${YELLOW}Checking Docker Services...${NC}"
if docker ps >/dev/null 2>&1; then
    DOCKER_COUNT=$(docker ps -q | wc -l | tr -d ' ')
    if [ "$DOCKER_COUNT" -gt 0 ]; then
        echo -e "  ${GREEN}✓${NC} $DOCKER_COUNT Docker containers running"
        
        # Check Onyx specific containers
        if docker ps | grep -q "onyx"; then
            echo -e "  ${GREEN}✓${NC} Onyx stack detected"
        fi
    else
        echo -e "  ${GRAY}○${NC} No Docker containers running"
    fi
else
    echo -e "  ${GRAY}○${NC} Docker is not running or not installed"
fi

echo

# DNS checks
echo -e "${YELLOW}Checking DNS entries...${NC}"
for domain in "cosmic.board" "loopify.sam" "loopify.dev" "prism.ai"; do
    if grep -q "$domain" /etc/hosts; then
        echo -e "  ${GREEN}✓${NC} $domain configured in /etc/hosts"
    else
        echo -e "  ${YELLOW}⚠${NC} $domain not in /etc/hosts"
        echo -e "    ${GRAY}Add: echo '127.0.0.1 $domain' | sudo tee -a /etc/hosts${NC}"
    fi
done

echo
echo -e "${BLUE}Summary:${NC}"
echo "  Use ${GREEN}./list-services.sh${NC} for detailed service list"
echo "  Use ${GREEN}./update-nginx.sh${NC} to apply configuration changes"
echo "  Use ${GREEN}./port-scanner.py --check <port>${NC} to check specific ports"