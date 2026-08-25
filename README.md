---
# 🔐 Tunnel Signer + Dynamic Reverse‑Tunnel Router Template

## 📌 Overview

This repository provides a standardized framework for building, installing, and managing the **Tunnel Signer + Dynamic Reverse‑Tunnel Router** system.  

It automates secure exposure of local services from **WSL/Linux clients** to a central VM using **reverse SSH tunnels** and **dynamic Nginx routing**, with token‑based authentication and short‑lived SSH certificates.
---

---

## 🎯 Objective

- Provide a reusable template for tunneling + routing modules  
- Automate dependency cloning and installation via Gradle  
- Support version pinning (branch, tag, commit) and `latest` keyword  
- Simplify uninstall workflows with reversible scripts  
- Enable composite builds for scaling across multiple tunnel services  
- Enforce per‑user isolation with token‑based authentication  

---
```
## 📂 Repository Structure

tunnel-signer-template/
│
├── build.gradle        → Gradle tasks (install, uninstall, build, deploy)
├── deps.gradle         → External dependencies (repo + version or 'latest')
├── settings.gradle     → Composite build inclusion for dependencies
│
├── src/                → Source code & scripts
│   ├── sign_service.py → SSH certificate signing API
│   ├── regen_nginx_routes.sh → Dynamic Nginx route generator
│   ├── install.sh      → Installer script (system/user setup)
│   └── uninstall.sh    → Uninstaller script (reverse install steps)
│
├── etc/tunnel/         → Token + port mapping stores
│   ├── tunnel_tokens.json
│   └── user_ports.json
│
└── README.md
```



## ⚙️ Dependency Management

Dependencies declared in `deps.gradle`:

```groovy
ext.org = "bit-faas"

ext.deps = [
    [repo: "nginx-config-template", version: "latest"],
    [repo: "ssh-ca-tools", version: "main"],
    [repo: "token-manager", version: "v1.0.0"]
]
```

---
Gradle clones each dependency into build/deps/ and runs its :install task.

latest keyword fetches the most recent commit from default branch.
---
---
🛠️ Install & Uninstall Scripts
install.sh:

Creates SSH CA under /etc/ssh/ca/

Installs sign_service.py as a systemd service

Initializes token + port stores

Configures Nginx structure
---
---

uninstall.sh:

Stops signing service

Removes CA + token stores

Cleans Nginx configs

Gradle tasks wrap these scripts:

```bash
./gradlew install
./gradlew uninstall
```
---
---
🚀 Usage
Clone this template to create a new tunnel repository.

Define dependencies in deps.gradle.

Implement tunnel logic in src/.

Run:

```bash
./gradlew install
./gradlew build
./gradlew deploy
```
To remove:

```bash
./gradlew uninstall
```
🔑 Token Store Format
```json
{
  "tokens": {
    "<token>": {
      "name": "gitlab",
      "principals": ["bitone"],
      "port": 9002,
      "max_cert_ttl": 3600,
      "active": true
    }
  }
}
```
---
---
Validation rules:

name must be non‑empty

port must exist and be unique

active must be true to sign certificates

🌐 Nginx Routing
For each active token:

```Code
server_name <name>.bitone.in;
proxy_pass http://127.0.0.1:<port>;
```
Routing regeneration ensures atomic updates and safe reloads.

🔄 Operational Workflow
Add user → sudo add_token.sh "alice" "principal" 3600

Client connection →

```bash
ssh -N -R 127.0.0.1:<assigned_port>:localhost:8080 principal@bitone.in
```
Revoke token → sudo revoke_token.sh <token>
---
---

📈 Benefits
Secure WSL → VM tunneling

Per‑user isolation with subdomains

Automated dependency + install flow

Token‑based authentication with revocation

CI/CD ready with composite builds
---
