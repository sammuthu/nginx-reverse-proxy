#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/sammuthu/Projects/nginx-reverse-proxy"
NGINX_CONF="/opt/homebrew/etc/nginx/nginx.conf"
CURRENT_SYMLINK_TARGET=$(readlink "$NGINX_CONF" 2>/dev/null)

echo -e "${BLUE}=== Nginx Configuration Update ===${NC}"
echo

# Check current nginx configuration
echo -e "${YELLOW}Checking current nginx configuration...${NC}"
if [ -L "$NGINX_CONF" ]; then
    echo -e "Current config is symlinked to: ${BLUE}$CURRENT_SYMLINK_TARGET${NC}"
else
    echo -e "${YELLOW}Warning: nginx.conf is not a symlink${NC}"
fi

# Backup current configuration
echo -e "${YELLOW}Creating backup...${NC}"
BACKUP_DIR="$PROJECT_ROOT/backups"
mkdir -p "$BACKUP_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [ -f "$NGINX_CONF" ] || [ -L "$NGINX_CONF" ]; then
    cp -P "$NGINX_CONF" "$BACKUP_DIR/nginx.conf.backup.$TIMESTAMP"
    echo -e "${GREEN}Backup created: $BACKUP_DIR/nginx.conf.backup.$TIMESTAMP${NC}"
fi

# Test new configuration
echo -e "${YELLOW}Testing new configuration...${NC}"
nginx -t -c "$PROJECT_ROOT/config/nginx.conf" 2>&1

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Configuration test failed!${NC}"
    echo -e "${RED}Please fix the configuration and try again.${NC}"
    exit 1
fi

echo -e "${GREEN}Configuration test passed!${NC}"

# Update symlink
echo -e "${YELLOW}Updating nginx configuration symlink...${NC}"
if [ -f "$NGINX_CONF" ] || [ -L "$NGINX_CONF" ]; then
    rm "$NGINX_CONF"
fi

ln -s "$PROJECT_ROOT/config/nginx.conf" "$NGINX_CONF"
echo -e "${GREEN}Symlink updated: $NGINX_CONF -> $PROJECT_ROOT/config/nginx.conf${NC}"

# Restart nginx
echo -e "${YELLOW}Restarting nginx...${NC}"
brew services restart nginx

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Nginx restarted successfully!${NC}"
else
    echo -e "${RED}Failed to restart nginx${NC}"
    echo -e "${YELLOW}Restoring backup...${NC}"
    rm "$NGINX_CONF"
    cp "$BACKUP_DIR/nginx.conf.backup.$TIMESTAMP" "$NGINX_CONF"
    brew services restart nginx
    echo -e "${RED}Configuration rolled back${NC}"
    exit 1
fi

# Verify nginx is running
sleep 2
if brew services list | grep nginx | grep -q started; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
    exit 1
fi

echo
echo -e "${GREEN}=== Configuration Update Complete ===${NC}"
echo
echo -e "${BLUE}Active sites:${NC}"
ls -1 "$PROJECT_ROOT/config/sites-enabled/" | sed 's/\.conf$//' | while read site; do
    echo "  • $site"
done