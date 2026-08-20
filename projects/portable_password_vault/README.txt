====================================================
 🧠 PORTABLE PASSWORD VAULT (PEN DRIVE EDITION)
====================================================

This folder contains your password vault configured to run on ANY computer.

----------------------------------------------------
💻 FOR WINDOWS (Easiest & Recommended)
----------------------------------------------------
1. Double-click "resilient_vault.html".
2. It opens offline in Microsoft Edge or Google Chrome.
3. Enter your Master Password to access your passwords.

Alternative (Git Bash on Windows):
1. Right-click inside this USB folder -> "Open Git Bash here".
2. Type: ./v

----------------------------------------------------
🐧 FOR LINUX
----------------------------------------------------
1. Open a terminal inside this USB folder.
2. Run:
   ./v           (Opens interactive fzf search)
   ./v <query>   (Searches & copies password directly)

   Example: ./v twitter

----------------------------------------------------
📁 CONTENTS IN THIS FOLDER:
----------------------------------------------------
- v                    : Portable Linux CLI binary
- resilient_vault.html : Portable Web Vault (Windows/Mac/Linux/Android)
- .lazy_vault/         : Encrypted vault data (vault.enc & vault.salt)
