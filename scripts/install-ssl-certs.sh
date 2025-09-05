#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/sammuthu/Projects/nginx-reverse-proxy"
SSL_DIR="$PROJECT_ROOT/sslCerts"

echo -e "${BLUE}=== Installing SSL Certificates in System Keychain ===${NC}"
echo
echo -e "${YELLOW}This script will install and trust the SSL certificates for local development.${NC}"
echo -e "${YELLOW}You will be prompted for your password to add certificates to the system keychain.${NC}"
echo

# Define services
services=("cosmic-board" "cosmic-board-mobile" "loopify" "prism-ai" "sammuthu-dev")

# Function to install certificate in macOS keychain
install_cert() {
    local cert_name=$1
    local cert_file="$SSL_DIR/${cert_name}.crt"
    
    if [ ! -f "$cert_file" ]; then
        echo -e "  ${RED}✗${NC} Certificate not found: $cert_file"
        echo -e "    Run ./scripts/generate-ssl-certs.sh first"
        return 1
    fi
    
    echo -e "Installing ${BLUE}${cert_name}${NC} certificate..."
    
    # Remove certificate if it already exists (to update it)
    sudo security delete-certificate -c "${cert_name}" /Library/Keychains/System.keychain 2>/dev/null
    
    # Add certificate to system keychain and trust it
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$cert_file"
    
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} Certificate installed and trusted"
        return 0
    else
        echo -e "  ${YELLOW}⚠${NC} Failed to install certificate"
        return 1
    fi
}

# Install all certificates
success_count=0
for service in "${services[@]}"; do
    if install_cert "$service"; then
        ((success_count++))
    fi
    echo
done

echo -e "${BLUE}=== Installation Summary ===${NC}"
echo -e "Successfully installed: ${GREEN}$success_count${NC} out of ${#services[@]} certificates"
echo

if [ $success_count -eq ${#services[@]} ]; then
    echo -e "${GREEN}✓ All certificates installed successfully!${NC}"
    echo
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Update nginx configuration: ./scripts/update-nginx.sh"
    echo "2. The services will be accessible via HTTPS:"
    echo "   • https://cosmic.board"
    echo "   • https://m.cosmic.board"
    echo "   • https://loopify.sam"
    echo "   • https://loopify.dev"
    echo "   • https://prism.ai"
    echo "   • https://sammuthu.dev"
    echo
    echo -e "${BLUE}For other devices on the network:${NC}"
    echo "1. Install the certificates on each device"
    echo "2. Or accept the security warning when browsing"
else
    echo -e "${YELLOW}⚠ Some certificates failed to install${NC}"
    echo "You can manually trust them in Keychain Access:"
    echo "1. Open Keychain Access"
    echo "2. Go to System keychain"
    echo "3. Find the certificate"
    echo "4. Double-click and set Trust to 'Always Trust'"
fi

echo
echo -e "${GREEN}=== Installation Complete ===${NC}"