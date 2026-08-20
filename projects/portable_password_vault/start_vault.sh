#!/bin/bash
# Portable Vault Server Starter for Linux

PORT=9090
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Starting Portable Password Vault Server..."
echo "--------------------------------------------------"

# Get Local IP Address
IP=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)

echo "💻 Local Access:   http://localhost:$PORT/resilient_vault.html"
if [ -n "$IP" ]; then
    echo "📱 Mobile/WiFi IP: http://$IP:$PORT/resilient_vault.html"
fi
echo "--------------------------------------------------"
echo "Press Ctrl+C to stop the server."

python3 -m http.server $PORT --directory "$DIR"
