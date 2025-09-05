#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/sammuthu/Projects/nginx-reverse-proxy"
SSL_DIR="$PROJECT_ROOT/sslCerts"

echo -e "${BLUE}=== Creating Certificate Bundle ===${NC}"
echo

# Create iOS configuration profile for easy installation
cat > "$SSL_DIR/LocalDevCerts.mobileconfig" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PayloadContent</key>
    <array>
EOF

# Function to add certificate to profile
add_cert_to_profile() {
    local cert_file=$1
    local cert_name=$2
    
    if [ -f "$cert_file" ]; then
        # Extract just the certificate content
        cert_content=$(cat "$cert_file" | sed '/-----BEGIN/d' | sed '/-----END/d' | tr -d '\n')
        
        cat >> "$SSL_DIR/LocalDevCerts.mobileconfig" << EOF
        <dict>
            <key>PayloadCertificateFileName</key>
            <string>$cert_name</string>
            <key>PayloadContent</key>
            <data>
$cert_content
            </data>
            <key>PayloadDescription</key>
            <string>Local Development Certificate for $cert_name</string>
            <key>PayloadDisplayName</key>
            <string>$cert_name</string>
            <key>PayloadIdentifier</key>
            <string>com.local.dev.$cert_name</string>
            <key>PayloadType</key>
            <string>com.apple.security.root</string>
            <key>PayloadUUID</key>
            <string>$(uuidgen)</string>
            <key>PayloadVersion</key>
            <integer>1</integer>
        </dict>
EOF
    fi
}

# Add all certificates
add_cert_to_profile "$SSL_DIR/cosmic-board.crt" "cosmic.board"
add_cert_to_profile "$SSL_DIR/cosmic-board-mobile.crt" "m.cosmic.board"
add_cert_to_profile "$SSL_DIR/loopify.crt" "loopify"
add_cert_to_profile "$SSL_DIR/prism-ai.crt" "prism.ai"
add_cert_to_profile "$SSL_DIR/sammuthu-dev.crt" "sammuthu.dev"

# Complete the profile
cat >> "$SSL_DIR/LocalDevCerts.mobileconfig" << 'EOF'
    </array>
    <key>PayloadDescription</key>
    <string>Local Development SSL Certificates</string>
    <key>PayloadDisplayName</key>
    <string>Local Dev Certificates</string>
    <key>PayloadIdentifier</key>
    <string>com.local.dev.certificates</string>
    <key>PayloadOrganization</key>
    <string>Local Development</string>
    <key>PayloadRemovalDisallowed</key>
    <false/>
    <key>PayloadType</key>
    <string>Configuration</string>
    <key>PayloadUUID</key>
    <string>$(uuidgen)</string>
    <key>PayloadVersion</key>
    <integer>1</integer>
</dict>
</plist>
EOF

echo -e "${GREEN}✓ Created iOS configuration profile: LocalDevCerts.mobileconfig${NC}"

# Create a combined PEM bundle for other uses
cat "$SSL_DIR"/*.crt > "$SSL_DIR/all-certs-bundle.pem"
echo -e "${GREEN}✓ Created certificate bundle: all-certs-bundle.pem${NC}"

echo
echo -e "${BLUE}=== How to Install ===${NC}"
echo
echo -e "${YELLOW}For iOS devices (iPhone/iPad):${NC}"
echo "1. Run: ./scripts/serve-certs.sh"
echo "2. On iOS device, visit: http://192.168.0.18:8888"
echo "3. Download 'LocalDevCerts.mobileconfig'"
echo "4. Go to Settings → Downloaded Profile → Install"
echo "5. Then Settings → General → About → Certificate Trust Settings"
echo "6. Enable trust for each certificate"
echo
echo -e "${YELLOW}For macOS:${NC}"
echo "1. Run: ./scripts/serve-certs.sh"
echo "2. Visit: http://192.168.0.18:8888"
echo "3. Download individual certificates"
echo "4. Double-click to install in Keychain Access"
echo "5. Trust each certificate"
echo
echo -e "${GREEN}Files created in: $SSL_DIR${NC}"