#!/bin/bash
# Creates a throwaway test CA and a server certificate for the local Prosody.
# The CA is installed into the iOS simulator as a trusted root so Monal's
# TLS checks pass without weakening any app settings.
set -euo pipefail
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/certs"
domain="kim.localtest.me"
mkdir -p "$dir"
cd "$dir"

openssl req -x509 -newkey rsa:2048 -nodes -days 825 \
    -keyout test-ca.key -out test-ca.crt \
    -subj "/CN=StreamScape KIM Local Test CA" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign"

openssl req -newkey rsa:2048 -nodes \
    -keyout "$domain.key" -out "$domain.csr" -subj "/CN=$domain"

cat > leaf.ext <<EOF
basicConstraints=CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=DNS:$domain,DNS:*.$domain
EOF

# 825 days is Apple's maximum accepted lifetime for TLS server certificates.
openssl x509 -req -in "$domain.csr" -CA test-ca.crt -CAkey test-ca.key \
    -CAcreateserial -days 825 -sha256 -extfile leaf.ext -out "$domain.crt"
rm -f "$domain.csr" leaf.ext test-ca.srl
chmod 644 "$domain.key" "$domain.crt"
echo "Certificates written to $dir"
