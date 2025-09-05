#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_ROOT="/Users/sammuthu/Projects/nginx-reverse-proxy"
SSL_DIR="$PROJECT_ROOT/sslCerts"
PORT=8888

echo -e "${BLUE}=== SSL Certificate Server ===${NC}"
echo
echo -e "${YELLOW}Starting web server to distribute certificates...${NC}"
echo -e "${GREEN}Certificates will be available at:${NC}"
echo
echo -e "${BLUE}From other devices, visit:${NC}"
echo -e "  http://192.168.0.18:$PORT"
echo
echo -e "${BLUE}Individual certificates:${NC}"
echo -e "  • http://192.168.0.18:$PORT/cosmic-board.crt"
echo -e "  • http://192.168.0.18:$PORT/cosmic-board-mobile.crt"
echo -e "  • http://192.168.0.18:$PORT/loopify.crt"
echo -e "  • http://192.168.0.18:$PORT/prism-ai.crt"
echo -e "  • http://192.168.0.18:$PORT/sammuthu-dev.crt"
echo
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo

# Create a simple HTML index page
cat > "$SSL_DIR/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Local Development Certificates</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            max-width: 600px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h1 { color: #333; }
        .cert-list {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin: 20px 0;
        }
        .cert-item {
            margin: 15px 0;
            padding: 15px;
            background: #f9f9f9;
            border-radius: 4px;
        }
        .cert-item a {
            display: block;
            padding: 10px;
            background: #007aff;
            color: white;
            text-decoration: none;
            border-radius: 4px;
            text-align: center;
            margin-top: 10px;
        }
        .instructions {
            background: #fff3cd;
            border: 1px solid #ffc107;
            border-radius: 4px;
            padding: 15px;
            margin: 20px 0;
        }
        .device-section {
            margin: 20px 0;
            padding: 15px;
            background: white;
            border-radius: 8px;
        }
        h2 { color: #555; font-size: 1.2em; }
        code {
            background: #f4f4f4;
            padding: 2px 6px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <h1>🔐 Local Development SSL Certificates</h1>
    
    <div class="instructions">
        <strong>⚠️ Important:</strong> These are self-signed certificates for local development only.
    </div>

    <div class="cert-list">
        <h2>Download Certificates</h2>
        
        <div class="cert-item">
            <strong>CosmicBoard</strong> (cosmic.board)
            <a href="cosmic-board.crt" download>Download cosmic-board.crt</a>
        </div>
        
        <div class="cert-item">
            <strong>CosmicBoard Mobile</strong> (m.cosmic.board)
            <a href="cosmic-board-mobile.crt" download>Download cosmic-board-mobile.crt</a>
        </div>
        
        <div class="cert-item">
            <strong>Loopify</strong> (loopify.sam, loopify.dev)
            <a href="loopify.crt" download>Download loopify.crt</a>
        </div>
        
        <div class="cert-item">
            <strong>Prism AI</strong> (prism.ai)
            <a href="prism-ai.crt" download>Download prism-ai.crt</a>
        </div>
        
        <div class="cert-item">
            <strong>Sammuthu Dev</strong> (sammuthu.dev)
            <a href="sammuthu-dev.crt" download>Download sammuthu-dev.crt</a>
        </div>
    </div>

    <div class="device-section">
        <h2>📱 iOS Installation (iPhone/iPad)</h2>
        <ol>
            <li>Download the certificate(s) above on your iOS device</li>
            <li>Go to <strong>Settings → General → VPN & Device Management</strong></li>
            <li>Under "Downloaded Profile", tap the certificate</li>
            <li>Tap "Install" and enter your passcode</li>
            <li>Tap "Install" again, then "Done"</li>
            <li><strong>Important:</strong> Go to <strong>Settings → General → About → Certificate Trust Settings</strong></li>
            <li>Enable "Full Root Certificate Trust" for the certificate</li>
        </ol>
    </div>

    <div class="device-section">
        <h2>💻 macOS Installation</h2>
        <ol>
            <li>Download the certificate(s) above</li>
            <li>Double-click the .crt file to open in Keychain Access</li>
            <li>Select "System" keychain when prompted</li>
            <li>Find the certificate in Keychain Access</li>
            <li>Double-click it, expand "Trust"</li>
            <li>Set "When using this certificate" to "Always Trust"</li>
            <li>Close and enter your password to save</li>
        </ol>
    </div>

    <div class="device-section">
        <h2>🌐 Configured Domains</h2>
        <p>After installing certificates, these domains will work over HTTPS:</p>
        <ul>
            <li>https://cosmic.board</li>
            <li>https://m.cosmic.board</li>
            <li>https://loopify.sam</li>
            <li>https://loopify.dev</li>
            <li>https://prism.ai</li>
            <li>https://sammuthu.dev</li>
        </ul>
        <p><code>Note: Devices must use 192.168.0.18 as DNS server or have hosts entries</code></p>
    </div>
</body>
</html>
EOF

# Start Python HTTP server
cd "$SSL_DIR"
python3 -m http.server $PORT --bind 0.0.0.0