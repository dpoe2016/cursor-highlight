#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Cursor Highlight"
BUNDLE_ID="com.dpoe2016.cursor-highlight"
EXECUTABLE="cursor-highlight"
BUILD_DIR="build"
APP_DIR="$BUILD_DIR/$APP_NAME.app"
CERT_NAME="CursorHighlightDev"

# --- Ensure a persistent self-signed code-signing certificate exists ---
ensure_cert() {
    if security find-identity -v -p codesigning 2>/dev/null | grep -q "$CERT_NAME"; then
        return 0
    fi

    echo "==> Creating self-signed code-signing certificate (one-time)..."
    local TMPDIR
    TMPDIR=$(mktemp -d)

    cat > "$TMPDIR/cert.conf" <<CERTEOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = codesign

[dn]
CN = $CERT_NAME

[codesign]
keyUsage = critical, digitalSignature
extendedKeyUsage = codeSigning
basicConstraints = critical, CA:false
CERTEOF

    openssl req -x509 -newkey rsa:2048 \
        -keyout "$TMPDIR/key.pem" -out "$TMPDIR/cert.pem" \
        -days 3650 -nodes -config "$TMPDIR/cert.conf" 2>/dev/null

    openssl pkcs12 -export -legacy \
        -out "$TMPDIR/cert.p12" \
        -inkey "$TMPDIR/key.pem" -in "$TMPDIR/cert.pem" \
        -passout pass:temppass 2>/dev/null

    security import "$TMPDIR/cert.p12" \
        -k ~/Library/Keychains/login.keychain-db \
        -P "temppass" -T /usr/bin/codesign

    # Trust certificate for code signing (may prompt for password)
    echo "    You may be prompted for your macOS password to trust the certificate."
    security add-trusted-cert -p codeSign \
        -k ~/Library/Keychains/login.keychain-db "$TMPDIR/cert.pem" || true

    rm -rf "$TMPDIR"
    echo "==> Certificate '$CERT_NAME' created and trusted."
}

ensure_cert

echo "==> Building $APP_NAME..."
swift build -c release 2>&1

echo "==> Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# Copy binary
cp ".build/release/$EXECUTABLE" "$APP_DIR/Contents/MacOS/$EXECUTABLE"

# Create Info.plist
cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> Signing app bundle with certificate '$CERT_NAME'..."
codesign --force --sign "$CERT_NAME" --identifier "$BUNDLE_ID" --deep "$APP_DIR"

echo "==> Done! App bundle created at: $APP_DIR"
echo ""
echo "To install, run:"
echo "  cp -r \"$APP_DIR\" /Applications/"
echo ""
echo "To run directly:"
echo "  open \"$APP_DIR\""
