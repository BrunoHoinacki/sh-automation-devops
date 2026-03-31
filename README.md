# DevOps Automation Toolbox (Bash)

A modular, menu-driven toolbox to bootstrap and maintain **Ubuntu/Debian VPS** environments.

This toolbox can prepare the base user for you.
You can start as `root`, create the `devops` user, install Docker and the rest of the stack, then log in as that user and continue the setup.

Main features:
- Create/update a `devops` user with `sudo` and `docker` group access
- GitHub SSH key setup (generate + pause + test)
- System updates
- Docker & Docker Compose
- PHP (choose version)
- Composer
- Node.js & NPM (choose version)
- Open ports inspection and firewall management (UFW)

---

## Repository Structure

```text
sh-automation-devops/
├── install.sh              # One-line installer (curl | bash)
├── devops.sh               # Interactive menu
├── lib/
│   └── common.sh           # Shared helpers
└── modules/
    ├── 00_user_devops.sh   # Create/update devops user and add sudo/docker groups
    ├── 01_ssh_user.sh      # GitHub SSH setup
    ├── 02_system_update.sh
    ├── 03_docker.sh
    ├── 04_php.sh
    ├── 05_composer.sh
    ├── 06_node.sh
    └── 07_ports.sh
```

---

## Requirements

- Ubuntu or Debian VPS
- Root access or a user with `sudo`
- Internet access

---

## Quick Start (Recommended)

### One-liner install (curl | bash)

Downloads the toolbox **into the current directory**, prepares permissions, and opens the menu.

```bash
curl -fsSL https://raw.githubusercontent.com/BrunoHoinacki/sh-automation-devops/main/install.sh | bash
```

What this does:

- Downloads the repository
- Extracts it **where you are**
- Makes scripts executable
- Starts the toolbox menu automatically

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

1. SSH into your VPS as `root` on the first access
2. Go to any folder you like (`~`, `/srv`, `/tools`, etc.)
3. Run the installer
4. Create/update the `devops` user from the menu
5. Install Docker and the rest of the stack
6. Log in as `devops` and continue your normal workflow

Example:

```bash
ssh root@your-server
mkdir -p /root/tools && cd /root/tools
curl -fsSL https://raw.githubusercontent.com/BrunoHoinacki/sh-automation-devops/main/install.sh | bash
```

---

## Toolbox Menu Overview

### 1) Create/update DevOps user (sudo + docker)

- Creates the Linux user (default: `devops`) if it does not exist
- Adds the user to `sudo`
- Adds the user to `docker`
- Creates the `docker` group if Docker has not been installed yet
- Can also be used later to re-apply group membership

This is the best first step on a fresh VPS.

---

### 2) GitHub SSH setup (generate key + test)

- Generates an **ed25519 SSH key** for an existing Linux user
- Prints the **public key** to copy into GitHub
- **Pauses execution** so you can add the key to GitHub
- After pressing ENTER, tests authentication with:

```bash
ssh -T git@github.com
```

This module is ideal for preparing the server to work with GitHub repositories.

---

### 3) System update & upgrade

Runs:

- `apt update`
- `apt upgrade`
- `apt autoremove`
- `apt autoclean`

---

### 4) Install Docker + Compose plugin

Installs:

- Docker CE
- Docker Buildx
- Docker Compose plugin (`docker compose`)

Also:

- Enables Docker service
- Starts Docker automatically on boot
- Works whether the `docker` group already existed or not

After installing Docker, log in again as your target user so Docker group membership is applied to the shell session.

---

### 5) Install PHP (choose version)

- Prompts for PHP version (examples: `8.1`, `8.2`, `8.3`)
- Installs common extensions used in Laravel and modern PHP stacks

---

### 6) Install Composer

- Installs Composer globally at:

```text
/usr/local/bin/composer
```

- Optionally updates Composer if already installed

---

### 7) Install Node.js + NPM (choose version)

- Prompts for Node major version (examples: `18`, `20`, `22`)
- Installs via NodeSource
- Includes `npm`

---

### 8) Check open ports + close with UFW

- Lists listening ports using `ss -tulpn`
- Displays current UFW status
- Optionally enables UFW
- Allows closing a specific port using:
  - TCP
  - UDP
  - Both

---

## Usage Notes (Important)

- Always run the toolbox using:

```bash
sudo ./devops.sh
```

- On a brand-new server, a practical flow is:

```bash
sudo ./devops.sh
# 1) create devops user
# 3) update system
# 4) install Docker
```

- Some modules add official repositories:
  - Docker
  - NodeSource
  - `ondrej/php` PPA
- On production servers, be careful when enabling UFW or blocking ports.

---

## Suggested VPS Baseline Workflow

1. **Create/update DevOps user**
2. **System update**
3. **Install Docker**
4. **Log in again as `devops`**
5. **GitHub SSH setup**
6. **Install PHP + Composer** (if needed)
7. **Install Node/NPM** (if needed)
8. **Review ports and enable firewall**

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

- Add new features as standalone modules in `modules/`
- Keep modules small and single-purpose
- Reuse helpers from `lib/common.sh`

---

## License

MIT (recommended).
Add a `LICENSE` file if you want this explicitly.
