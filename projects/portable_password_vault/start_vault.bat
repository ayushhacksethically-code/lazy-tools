@echo off
title Portable Password Vault Server
set PORT=9090

echo 🚀 Starting Portable Password Vault Server for Windows...
echo --------------------------------------------------

for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do set IP=%%a
set IP=%IP: =%

echo 💻 Local Access:   http://localhost:%PORT%/resilient_vault.html
echo 📱 Mobile/WiFi IP: http://%IP%:%PORT%/resilient_vault.html
echo --------------------------------------------------
echo Press Ctrl+C to stop the server.

python -m http.server %PORT%
pause
