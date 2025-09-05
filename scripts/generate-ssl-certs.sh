#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/sammuthu/Projects/nginx-reverse-proxy"
SSL_DIR="$PROJECT_ROOT/sslCerts"
CERT_VALIDITY=365  # Days

echo -e "${BLUE}=== SSL Certificate Generation for Local Services ===${NC}"
echo

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Define services and their domains (using arrays for compatibility)
services=("cosmic-board:cosmic.board" "cosmic-board-mobile:m.cosmic.board" "loopify:loopify.sam,loopify.dev" "prism-ai:prism.ai" "sammuthu-dev:sammuthu.dev")

# Function to generate certificate for a service
generate_cert() {
    local service_name=$1
    local domains=$2
    
    echo -e "${YELLOW}Generating certificate for $service_name...${NC}"
    
    # Prepare certificate files
    local key_file="$SSL_DIR/${service_name}.key"
    local cert_file="$SSL_DIR/${service_name}.crt"
    local csr_file="$SSL_DIR/${service_name}.csr"
    local config_file="$SSL_DIR/${service_name}.conf"
    
    # Create OpenSSL config file for multiple domains
    cat > "$config_file" << EOF
[req]
default_bits = 2048
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = State
L = City
O = Local Development
OU = Dev
CN = ${domains%%,*}

[v3_req]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
EOF
    
    # Add all domains to alt_names
    local i=1
    IFS=',' read -ra ADDR <<< "$domains"
    for domain in "${ADDR[@]}"; do
        echo "DNS.$i = $domain" >> "$config_file"
        ((i++))
    done
    # Also add localhost and IP
    echo "DNS.$i = localhost" >> "$config_file"
    ((i++))
    echo "IP.1 = 127.0.0.1" >> "$config_file"
    echo "IP.2 = 192.168.0.18" >> "$config_file"
    
    # Generate private key
    openssl genrsa -out "$key_file" 2048 2>/dev/null
    
    # Generate certificate signing request
    openssl req -new -key "$key_file" -out "$csr_file" -config "$config_file" 2>/dev/null
    
    # Generate self-signed certificate
    openssl x509 -req -in "$csr_file" -signkey "$key_file" -out "$cert_file" \
        -days "$CERT_VALIDITY" -extensions v3_req -extfile "$config_file" 2>/dev/null
    
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        echo -e "  ${GREEN}✓${NC} Certificate generated: ${service_name}.crt"
        echo -e "  ${GREEN}✓${NC} Private key generated: ${service_name}.key"
        
        # Clean up CSR and config files
        rm -f "$csr_file" "$config_file"
    else
        echo -e "  ${RED}✗${NC} Failed to generate certificate for $service_name"
    fi
}

# Generate certificates for all services
for service_entry in "${services[@]}"; do
    IFS=':' read -r service_name domains <<< "$service_entry"
    generate_cert "$service_name" "$domains"
    echo
done

echo -e "${BLUE}=== Installing Certificates in System Keychain ===${NC}"
echo
echo -e "${YELLOW}To trust the certificates, you need to add them to your system keychain.${NC}"
echo -e "${YELLOW}You will be prompted for your password.${NC}"
echo

# Function to install certificate in macOS keychain
install_cert_macos() {
    local service_name=$1
    local cert_file="$SSL_DIR/${service_name}.crt"
    
    if [ -f "$cert_file" ]; then
        echo -e "Installing certificate for $service_name..."
        
        # Add certificate to system keychain
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$cert_file" 2>/dev/null
        
        if [ $? -eq 0 ]; then
            echo -e "  ${GREEN}✓${NC} Certificate installed and trusted"
        else
            echo -e "  ${YELLOW}⚠${NC} Certificate may already be installed or requires manual trust"
            echo -e "    To manually trust: Open Keychain Access > System > Certificates > Double-click cert > Trust > Always Trust"
        fi
    fi
}

# Ask if user wants to install certificates
echo -e "${BLUE}Do you want to install certificates in system keychain? (y/n)${NC}"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    for service_entry in "${services[@]}"; do
        IFS=':' read -r service_name domains <<< "$service_entry"
        install_cert_macos "$service_name"
    done
    echo
fi

echo -e "${BLUE}=== Certificate Summary ===${NC}"
echo
echo -e "${GREEN}Certificates generated in: $SSL_DIR${NC}"
ls -1 "$SSL_DIR"/*.crt 2>/dev/null | while read cert; do
    basename "$cert"
done

echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Run: ./scripts/update-nginx-ssl.sh to configure nginx for HTTPS"
echo "2. Restart nginx: brew services restart nginx"
echo "3. Access your services via HTTPS:"
for service_entry in "${services[@]}"; do
    IFS=':' read -r service_name domain_list <<< "$service_entry"
    IFS=',' read -ra domains <<< "$domain_list"
    for domain in "${domains[@]}"; do
        echo "   • https://$domain"
    done
done

echo
echo -e "${GREEN}=== Certificate Generation Complete ===${NC}"