# Installing SSL Certificates on Other Devices

## Quick Start - Serve Certificates

On your main Mac, run:
```bash
cd /Users/sammuthu/Projects/nginx-reverse-proxy
./scripts/serve-certs.sh
```

This starts a web server at `http://192.168.0.18:8888` where other devices can download certificates.

## Installation Instructions by Device

### 📱 iPhone/iPad (iOS)

1. **Open Safari** on your iPhone/iPad (must be Safari, not Chrome)
2. Go to `http://192.168.0.18:8888`
3. Tap each certificate link to download
4. You'll see "Profile Downloaded" - tap "Close"
5. Go to **Settings** → **General** → **VPN & Device Management**
6. Under "Downloaded Profile", tap the certificate
7. Tap "Install" (top right), enter your passcode
8. Tap "Install" again on the warning, then "Install" once more
9. Tap "Done"

**Critical Step for iOS:**
10. Go to **Settings** → **General** → **About** → **Certificate Trust Settings**
11. Toggle ON "Enable full trust" for each certificate you installed
12. Tap "Continue" on the warning

### 💻 Other Macs

**Method 1: Via Web Download**
1. Visit `http://192.168.0.18:8888` from the other Mac
2. Download each certificate
3. Double-click each `.crt` file
4. Choose "System" keychain and click "Add"
5. Open Keychain Access app
6. Find the certificate (search for "cosmic" or "loopify")
7. Double-click it, expand "Trust" section
8. Change "When using this certificate" to "Always Trust"
9. Close and enter password to save

**Method 2: Via AirDrop**
1. On main Mac, open Finder to `/Users/sammuthu/Projects/nginx-reverse-proxy/sslCerts`
2. Select all `.crt` files
3. Right-click → Share → AirDrop
4. Send to other Mac
5. Follow steps 3-9 from Method 1

### 🤖 Android

1. Go to `http://192.168.0.18:8888` in Chrome
2. Download certificates
3. Go to **Settings** → **Security** → **Encryption & credentials**
4. Tap **Install from storage** or **Install certificates**
5. Select "CA certificate"
6. Browse and select downloaded certificate
7. Give it a name and tap "OK"

## Verify Installation

After installing certificates, test by visiting:
- https://cosmic.board
- https://m.cosmic.board  
- https://loopify.sam
- https://loopify.dev
- https://prism.ai

You should see a padlock icon without warnings.

## Troubleshooting

### "This site can't be reached" on other devices
- Ensure the device is on the same network
- Check if device can ping `192.168.0.18`
- Add host entries or use your Mac as DNS server

### Certificate warnings persist on iOS
- Make sure you enabled "Full Trust" in Certificate Trust Settings
- Restart Safari or clear website data
- Some apps may not respect user-installed certificates

### Can't download on iOS
- Must use Safari, not Chrome
- If download fails, try emailing the .crt file to yourself
- Open email in Mail app and tap certificate to install

## Alternative: Accept Security Warning

Instead of installing certificates, users can:
1. Visit the HTTPS URL
2. See the warning
3. Tap "Advanced" or "Show Details"
4. Tap "Visit this website" or "Proceed anyway"
5. The site will work with HTTPS (connection is still encrypted)

This is simpler but users will see the warning each time.

## For Development Team

Consider using a service like [mkcert](https://github.com/FiloSottile/mkcert) which can create locally-trusted certificates that work across devices more easily.