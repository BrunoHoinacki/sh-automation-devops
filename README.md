# DevOps Automation Toolbox (Bash)

A modular, menu-driven toolbox to bootstrap and maintain Ubuntu/Debian VPS setups: create a `devops` user + SSH keys, install Docker/Compose, PHP (choose version), Composer, Node/NPM (choose version), run system updates, and inspect/close open ports via UFW.

Repo structure is intentionally simple:

```

sh-automation-devops/
├── devops.sh
├── lib/
│   └── common.sh
└── modules/
├── 01_ssh_user.sh
├── 02_system_update.sh
├── 03_docker.sh
├── 04_php.sh
├── 05_composer.sh
├── 06_node.sh
└── 07_ports.sh

````

---

## Requirements

- Ubuntu/Debian VPS
- Run as `root` or with `sudo`
- Internet access (to download packages and repositories)

---

## Quick Start (recommended)

### Option A) Clone and run

```bash
git clone git@github.com:BrunoHoinacki/sh-automation-devops.git
cd sh-automation-devops
chmod +x devops.sh modules/*.sh
sudo ./devops.sh
````

### Option B) Run without cloning (curl)

This downloads the repo as a tarball, extracts it, and runs the menu.

```bash
curl -fsSL https://codeload.github.com/BrunoHoinacki/sh-automation-devops/tar.gz/refs/heads/main \
  | sudo tar -xz -C /opt

sudo mv /opt/sh-automation-devops-* /opt/sh-automation-devops
sudo chmod +x /opt/sh-automation-devops/devops.sh /opt/sh-automation-devops/modules/*.sh
sudo /opt/sh-automation-devops/devops.sh
```

> Tip: after running once, you can keep it installed at `/opt/sh-automation-devops` and re-run anytime.

---

## What each module does

### 1) Create DevOps user + SSH key

* Creates a user (default: `devops`)
* Adds it to `sudo`
* Generates an `ed25519` SSH key under `~/.ssh/`
* Prints the **public key** to paste into GitHub

### 2) System update & upgrade

* `apt update`, `upgrade`, `autoremove`, `autoclean`

### 3) Install Docker + Compose plugin

* Installs Docker CE, Buildx, and `docker compose` plugin
* Enables and starts Docker service

### 4) Install PHP (choose version)

* Asks the PHP version (ex: 8.1 / 8.2 / 8.3)
* Installs common extensions for Laravel/modern stacks

### 5) Install Composer

* Installs Composer globally at `/usr/local/bin/composer`

### 6) Install Node.js + NPM (choose version)

* Asks Node major version (ex: 18 / 20 / 22)
* Installs via NodeSource

### 7) Check open ports + close with UFW

* Shows listening ports (`ss -tulpn`)
* Shows `ufw` status
* Optionally enables UFW
* Lets you deny a port (tcp/udp/both)

---

## Usage notes (important)

* Run the toolbox as root: `sudo ./devops.sh`
* Some modules add official repositories (Docker/NodeSource/PPA ondrej/php)
* If you’re running a production server, be careful with closing ports. Confirm your SSH port is allowed before enabling UFW.

---

## Common VPS baseline (suggested order)

1. **Create DevOps user + SSH key**
2. **System update**
3. **Install Docker**
4. **Install PHP + Composer** (if needed)
5. **Install Node/NPM** (if needed)
6. **Check ports + enable firewall**

---

## Security tip (UFW + SSH)

Before enabling UFW, ensure SSH is allowed:

```bash
sudo ufw allow OpenSSH
# or if using a custom ssh port, for example 2222:
sudo ufw allow 2222/tcp
```

---

## Contributing

PRs are welcome:

* new modules in `modules/`
* keep modules small and single-purpose
* reuse helpers from `lib/common.sh`

---

## License

MIT (recommended). Add a `LICENSE` file if you want this explicitly.