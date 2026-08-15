# 🧠 lazy_vault - Complete Technical & Security Documentation

`lazy_vault` (shortcut `v`) is an ultra-frictionless, offline-first password manager and generator written in **Nim**. It combines military-grade encryption with instant `fzf` fuzzy searching and automatic clipboard hygiene.

---

## 🛡️ Security Architecture

1. **AES-256-CBC Encryption**: Master vault (`~/.lazy_vault/vault.enc`) is encrypted using OpenSSL AES-256-CBC with PBKDF2 key derivation.
2. **PBKDF2 Key Derivation (600,000 Iterations)**: Derived using SHA-256 with 600,000 PBKDF2 iterations and a unique 256-bit salt (`~/.lazy_vault/vault.salt`).
3. **CSPRNG Password Generation**: Generates cryptographically secure passwords using OpenSSL kernel hardware entropy (`openssl rand`).
4. **15-Second Auto-Clear Clipboard**: Wipes copied secrets from clipboard automatically after 15 seconds.
5. **Emergency Recovery Key System**: Emergency recovery backup system (`v recovery` & `v recover`) ensures you can reset your Master Brain-PIN if forgotten.

---

## 🛠️ CLI Usage & Examples

### 1. Basic Operations
```bash
# Open interactive fzf search & copy secret to clipboard
v

# Direct search for a service
v google

# Add entry (auto-generates strong password if secret omitted)
v a google.com mysecretpassword

# Shortcut symbol add
v +github.com mygithubpass
```

### 2. Password Generator
```bash
# Generate 20-char strong password
v g 20

# Generate 6-digit PIN
v g 6 pin
```

### 3. Master Brain-PIN Change & Recovery
```bash
# Change Master Brain-PIN
v change-pin

# Setup Emergency Recovery Key
v recovery

# Reset Brain-PIN using Emergency Recovery Code
v recover
```

### 4. CSV Import & Export
```bash
# Export encrypted vault to CSV backup file
v export my_backup.csv

# Import CSV file into vault
v import my_passwords.csv
```

---

## 📊 Configuration Files

- **Source Code**: [`lazy_vault.nim`](file:///home/narayanas/projects/lazy_vault/lazy_vault.nim)
- **Binary Location**: `~/.local/bin/lazy_vault` (linked to `~/.local/bin/v`)
- **Vault Data Directory**: `~/.lazy_vault/`
