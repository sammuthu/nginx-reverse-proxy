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
echo -e "${BLUE}   Service Port Registry${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Function to check if port is in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo "Running"
    else
        echo "Stopped"
    fi
}

# Parse and display services
echo -e "${GREEN}Active Services:${NC}"
echo "----------------"
jq -r '.services[] | select(.status == "active") | "\(.port)|\(.name)|\(.domain // "N/A")"' "$REGISTRY_FILE" 2>/dev/null | while IFS='|' read -r port name domain; do
    status=$(check_port $port)
    if [ "$status" = "Running" ]; then
        status_color="${GREEN}●${NC}"
    else
        status_color="${RED}●${NC}"
    fi
    printf "  %s %-6s %-30s %s\n" "$status_color" "$port" "$name" "$domain"
done

echo
echo -e "${YELLOW}Configured Services:${NC}"
echo "--------------------"
jq -r '.services[] | select(.status == "configured") | "\(.port)|\(.name)|\(.domain // "N/A")"' "$REGISTRY_FILE" 2>/dev/null | while IFS='|' read -r port name domain; do
    status=$(check_port $port)
    if [ "$status" = "Running" ]; then
        status_color="${GREEN}●${NC}"
    else
        status_color="${YELLOW}○${NC}"
    fi
    printf "  %s %-6s %-30s %s\n" "$status_color" "$port" "$name" "$domain"
done

echo
echo -e "${BLUE}Docker Services:${NC}"
echo "----------------"
jq -r '.services[] | select(.status == "docker") | "\(.port)|\(.name)|\(.domain // "N/A")"' "$REGISTRY_FILE" 2>/dev/null | while IFS='|' read -r port name domain; do
    status=$(check_port $port)
    if [ "$status" = "Running" ]; then
        status_color="${GREEN}●${NC}"
    else
        status_color="${GRAY}○${NC}"
    fi
    printf "  %s %-6s %-30s %s\n" "$status_color" "$port" "$name" "$domain"
done

echo
echo -e "${GRAY}Not Configured:${NC}"
echo "---------------"
jq -r '.services[] | select(.status == "not_configured") | "\(.port // "N/A")|\(.name)|\(.notes // "")"' "$REGISTRY_FILE" 2>/dev/null | while IFS='|' read -r port name notes; do
    printf "  ${GRAY}○${NC} %-6s %-30s %s\n" "$port" "$name" "$notes"
done

echo
echo -e "${BLUE}Legend:${NC}"
echo "  ${GREEN}●${NC} Running"
echo "  ${RED}●${NC} Configured but stopped"
echo "  ${YELLOW}○${NC} Configured, not expected to run"
echo "  ${GRAY}○${NC} Not configured"
echo
echo -e "${BLUE}Quick Commands:${NC}"
echo "  View nginx config:  nginx -t"
echo "  Restart nginx:      brew services restart nginx"
echo "  Check port:         lsof -i :<port>"
echo "  Add new service:    ./add-service.sh"