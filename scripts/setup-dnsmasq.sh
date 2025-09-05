#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/sammuthu/Projects/nginx-reverse-proxy"
DNSMASQ_DIR="/opt/homebrew/etc/dnsmasq.d"
LOCAL_IP="192.168.0.18"

echo -e "${BLUE}=== DNSMasq Setup for Local Network Access ===${NC}"
echo

# Create symlinks for dnsmasq configurations
echo -e "${YELLOW}Setting up dnsmasq configuration symlinks...${NC}"

for conf_file in "$PROJECT_ROOT"/config/dnsmasq/*.conf; do
    filename=$(basename "$conf_file")
    target="$DNSMASQ_DIR/$filename"
    
    # Remove existing file/symlink if it exists
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo -e "  Removing existing: $target"
        sudo rm "$target"
    fi
    
    # Create symlink
    echo -e "  Creating symlink: $filename"
    sudo ln -s "$conf_file" "$target"
done

echo -e "${GREEN}✓ DNSMasq configurations symlinked${NC}"
echo

# Update /etc/hosts
echo -e "${YELLOW}Updating /etc/hosts...${NC}"

# Define all domains that should be accessible
declare -a domains=(
    "cosmic.board"
    "m.cosmic.board"
    "loopify.sam"
    "loopify.dev"
    "prism.ai"
)

echo -e "${BLUE}The following entries need to be in /etc/hosts:${NC}"
echo

for domain in "${domains[@]}"; do
    if ! grep -q "127.0.0.1.*$domain" /etc/hosts; then
        echo "127.0.0.1 $domain"
    fi
done

echo
echo -e "${YELLOW}To add missing entries, run:${NC}"
echo "sudo bash -c 'cat >> /etc/hosts' << EOF"
for domain in "${domains[@]}"; do
    if ! grep -q "127.0.0.1.*$domain" /etc/hosts; then
        echo "127.0.0.1 $domain"
    fi
done
echo "EOF"

echo
echo -e "${YELLOW}Restarting dnsmasq...${NC}"
sudo brew services restart dnsmasq

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ DNSMasq restarted successfully${NC}"
else
    echo -e "${RED}✗ Failed to restart DNSMasq${NC}"
    echo -e "${YELLOW}Try: sudo brew services start dnsmasq${NC}"
fi

echo
echo -e "${BLUE}=== Testing DNS Resolution ===${NC}"

# Test local resolution
for domain in "${domains[@]}"; do
    result=$(nslookup "$domain" 127.0.0.1 2>/dev/null | grep -A1 "Name:" | grep "Address:" | awk '{print $2}')
    if [ "$result" = "$LOCAL_IP" ]; then
        echo -e "  ${GREEN}✓${NC} $domain -> $LOCAL_IP"
    else
        echo -e "  ${RED}✗${NC} $domain (not resolving correctly)"
    fi
done

echo
echo -e "${BLUE}=== Configuration Complete ===${NC}"
echo
echo -e "${GREEN}Your services should now be accessible from other devices on the network:${NC}"
echo "  • http://cosmic.board - CosmicBoard"
echo "  • http://m.cosmic.board - CosmicBoard Mobile"  
echo "  • http://loopify.sam - Segment Loop Master"
echo "  • http://loopify.dev - Segment Loop Master (alt)"
echo "  • http://prism.ai - Prism AI"
echo
echo -e "${YELLOW}Note: Other devices must use $LOCAL_IP as their DNS server${NC}"
echo -e "${YELLOW}Or manually add entries to their hosts file pointing to $LOCAL_IP${NC}"