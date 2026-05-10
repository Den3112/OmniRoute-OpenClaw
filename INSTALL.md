# 📥 Installation Guide

This guide will help you install and configure the **OmniRoute-OpenClaw** AI aggregator on your system.

## 📋 Table of Contents
1. [System Requirements](#-system-requirements)
2. [Quick Start](#-quick-start)
3. [Platform-Specific Instructions](#-platform-specific-instructions)
4. [Configuration](#-configuration)
5. [Verification](#-verification)
6. [Troubleshooting](#-troubleshooting)

---

## 💻 System Requirements

### Minimum
- **CPU:** 2 Cores (x86_64 or ARM64)
- **RAM:** 4 GB
- **Disk:** 10 GB free space
- **OS:** Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+), macOS 12+, or Windows 10/11 with WSL2

### Recommended
- **CPU:** 4+ Cores
- **RAM:** 8 GB+
- **Disk:** 20 GB+ (SSD)

### Software
- **Docker:** 20.10+
- **Docker Compose:** v2.0+ (v1.x supported but not recommended)
- **Git:** 2.25+

---

## 🚀 Quick Start

The fastest way to get started is using our one-click installer:

```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh
```

This script will:
1. Check system requirements
2. Initialize submodules
3. Generate secure API keys and passwords
4. Build and start Docker containers

---

## 🍎 Platform-Specific Instructions

### 🐧 Linux (Ubuntu/Debian)
```bash
# Install Docker and Git
sudo apt update
sudo apt install -y docker.io docker-compose-v2 git

# Clone and Install
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
chmod +x *.sh
./update.sh
```

### 🍏 macOS
1. Install [Docker Desktop](https://www.docker.com/products/docker-desktop/)
2. Open Terminal and run:
```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh
```

### 🪟 Windows (WSL2)
1. Install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) (Ubuntu recommended)
2. Install [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/) and enable WSL2 integration
3. Open WSL2 terminal and run:
```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh
```

---

## ⚙️ Configuration

Settings are stored in the `.env` file. The installer generates secure defaults, but you may want to change:

- `OPENCLAW_PASSWORD`: The token used to access the OpenClaw gateway.
- `STORAGE_ENCRYPTION_KEY`: Used for encrypting sensitive data.
- `JWT_SECRET`: Used for dashboard authentication.

### Data Persistence
All data is stored in the `./data` directory:
- `./data/omniroute`: Database and configurations for OmniRoute
- `./data/openclaw`: Persistent state for OpenClaw

---

## ✅ Verification

After installation, verify that services are running:

1. **OmniRoute Dashboard:** [http://localhost:20128](http://localhost:20128)
   - Default login: `admin` / `admin`
2. **OpenClaw Gateway:** [http://localhost:18789](http://localhost:18789)
   - Status check: `curl http://localhost:18789/healthz`

---

## 🛠 Troubleshooting

If you encounter issues, please refer to the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) guide.

Common commands:
- `./status.sh`: Check system health
- `./logs.sh`: View real-time logs
- `./restart.sh`: Restart all services
- `./cleanup.sh`: Free up disk space
