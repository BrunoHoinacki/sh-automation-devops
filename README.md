# DevOps Automation Toolbox (Bash)

A modular, menu-driven toolbox to bootstrap and maintain **Ubuntu/Debian VPS** environments.

This toolbox is designed to be used **after your DevOps user already exists** (for example `devops`).  
You log in as that user, run the toolbox with `sudo`, and install or manage infrastructure components **on demand**.

Main features:
- GitHub SSH key setup (generate + pause + test)
- System updates
- Docker & Docker Compose
- PHP (choose version)
- Composer
- Node.js & NPM (choose version)
- Open ports inspection and firewall management (UFW)

---

## Repository Structure

```

sh-automation-devops/
├── install.sh              # One-line installer (curl | bash)
├── devops.sh               # Interactive menu
├── lib/
│   └── common.sh           # Shared helpers
└── modules/
├── 01_ssh_user.sh      # GitHub SSH setup (no user creation)
├── 02_system_update.sh
├── 03_docker.sh
├── 04_php.sh
├── 05_composer.sh
├── 06_node.sh
└── 07_ports.sh

````

---

## Requirements

- Ubuntu or Debian VPS
- Existing Linux user (recommended: `devops`)
- `sudo` privileges
- Internet access

---

## Quick Start (Recommended)

### 🚀 One-liner install (curl | bash)

Downloads the toolbox **into the current directory**, prepares permissions, and opens the menu.

```bash
curl -fsSL https://raw.githubusercontent.com/BrunoHoinacki/sh-automation-devops/main/install.sh | bash
````

What this does:

* Downloads the repository
* Extracts it **where you are**
* Makes scripts executable
* Starts the toolbox menu automatically

---

### Option B) Clone and run manually

```bash
git clone git@github.com:BrunoHoinacki/sh-automation-devops.git
cd sh-automation-devops
chmod +x install.sh devops.sh modules/*.sh
sudo ./devops.sh
```

---

## How to Use (Typical Flow)

You usually:

1. SSH into your VPS as `devops`
2. Go to any folder you like (`~`, `/srv`, `/tools`, etc.)
3. Run the installer
4. Use the interactive menu whenever needed

Example:

```bash
ssh devops@your-server
mkdir ~/tools && cd ~/tools
curl -fsSL https://raw.githubusercontent.com/BrunoHoinacki/sh-automation-devops/main/install.sh | bash
```

---

## Toolbox Menu Overview

### 1) GitHub SSH setup (generate key + test)

* Generates an **ed25519 SSH key** for the current Linux user
* Prints the **public key** to copy into GitHub
* **Pauses execution** so you can add the key to GitHub
* After pressing ENTER, tests authentication with:

```bash
ssh -T git@github.com
```

* Does **not** create or modify users

This module is ideal for quickly preparing a VPS to work with GitHub repositories.

---

### 2) System update & upgrade

Runs:

* `apt update`
* `apt upgrade`
* `apt autoremove`
* `apt autoclean`

---

### 3) Install Docker + Compose plugin

Installs:

* Docker CE
* Docker Buildx
* Docker Compose plugin (`docker compose`)

Also:

* Enables Docker service
* Starts Docker automatically on boot

---

### 4) Install PHP (choose version)

* Prompts for PHP version (examples: `8.1`, `8.2`, `8.3`)
* Installs common extensions used in Laravel and modern PHP stacks

---

### 5) Install Composer

* Installs Composer globally at:

```
/usr/local/bin/composer
```

* Optionally updates Composer if already installed

---

### 6) Install Node.js + NPM (choose version)

* Prompts for Node major version (examples: `18`, `20`, `22`)
* Installs via NodeSource
* Includes `npm`

---

### 7) Check open ports + close with UFW

* Lists listening ports using `ss -tulpn`
* Displays current UFW status
* Optionally enables UFW
* Allows closing a specific port using:

  * TCP
  * UDP
  * Both

---

## Usage Notes (Important)

* Always run the toolbox using:

```bash
sudo ./devops.sh
```

* Some modules add official repositories:

  * Docker
  * NodeSource
  * `ondrej/php` PPA
* On production servers, be careful when enabling UFW or blocking ports.

---

## Suggested VPS Baseline Workflow

1. **GitHub SSH setup**
2. **System update**
3. **Install Docker**
4. **Install PHP + Composer** (if needed)
5. **Install Node/NPM** (if needed)
6. **Review ports and enable firewall**

---

## Security Tip (UFW + SSH)

Before enabling UFW, ensure SSH access is allowed:

```bash
sudo ufw allow OpenSSH
```

Or, if using a custom SSH port (example: `2222`):

```bash
sudo ufw allow 2222/tcp
```

---

## Contributing

Pull requests are welcome.

Guidelines:

* Add new features as standalone modules in `modules/`
* Keep modules small and single-purpose
* Reuse helpers from `lib/common.sh`

---

## License

MIT (recommended).
Add a `LICENSE` file if you want this explicitly.
