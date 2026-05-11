# 📥 Installation Guide

Complete installation guide for OmniRoute + OpenClaw on different platforms.

---

## 📋 Table of Contents

1. [System Requirements](#-system-requirements)
2. [Quick Installation](#-quick-installation)
3. [Platform-Specific Instructions](#-platform-specific-instructions)
   - [Ubuntu/Debian](#ubuntudebian)
   - [macOS](#macos)
   - [Windows (WSL2)](#windows-wsl2)
   - [Other Linux Distributions](#other-linux-distributions)
4. [Manual Installation](#-manual-installation)
5. [Post-Installation](#-post-installation)
6. [Verification](#-verification)
7. [Troubleshooting](#-troubleshooting)

---

## 💻 System Requirements

### Minimum Requirements
- **CPU:** 2 cores
- **RAM:** 4 GB
- **Disk:** 10 GB free space
- **OS:** Linux, macOS, or Windows with WSL2

### Recommended Requirements
- **CPU:** 4+ cores
- **RAM:** 8 GB+
- **Disk:** 20 GB+ (SSD preferred)
- **OS:** Ubuntu 22.04+, macOS 12+, or Windows 11 with WSL2

### Required Software
- **Docker:** 20.10+ with Docker Compose plugin
- **Git:** 2.30+
- **Bash:** 4.0+ (for installation scripts)

---

## ⚡ Quick Installation

### One-Command Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

This will automatically:
- ✅ Check system requirements
- ✅ Install Docker if needed (on supported platforms)
- ✅ Clone the repository with submodules
- ✅ Generate secure encryption keys
- ✅ Build and start all containers
- ✅ Verify all services are healthy

**Installation time:** 5-15 minutes (depending on internet speed)

---

## 🖥 Platform-Specific Instructions

### Ubuntu/Debian

#### 1. Update System
```bash
sudo apt update && sudo apt upgrade -y
```

#### 2. Install Docker
```bash
# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Apply group changes (or logout/login)
newgrp docker

# Verify Docker installation
docker --version
docker compose version
```

#### 3. Install Git
```bash
sudo apt install -y git curl
```

#### 4. Run Installation
```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

### macOS

#### 1. Install Homebrew (if not installed)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### 2. Install Docker Desktop
```bash
brew install --cask docker
```

**Or download manually:** [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop/)

#### 3. Start Docker Desktop
- Open Docker Desktop from Applications
- Wait for Docker to start (whale icon in menu bar)
- Verify: `docker --version`

#### 4. Configure Docker Resources
- Open Docker Desktop → Settings → Resources
- **Memory:** Set to at least 4GB (8GB recommended)
- **CPUs:** Set to at least 2 cores (4 recommended)
- **Disk:** Ensure at least 20GB available

#### 5. Run Installation
```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

### Windows (WSL2)

#### 1. Enable WSL2
Open PowerShell as Administrator:
```powershell
wsl --install
```

Restart your computer.

#### 2. Install Ubuntu from Microsoft Store
- Open Microsoft Store
- Search for "Ubuntu 22.04 LTS"
- Click "Get" and install
- Launch Ubuntu and create a user account

#### 3. Install Docker Desktop for Windows
- Download: [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop/)
- Install and enable WSL2 integration
- Settings → Resources → WSL Integration → Enable Ubuntu

#### 4. Inside Ubuntu WSL2
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Git
sudo apt install -y git curl

# Run installation
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

### Other Linux Distributions

#### Fedora/RHEL/CentOS
```bash
# Install Docker
sudo dnf install -y docker docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install Git
sudo dnf install -y git curl

# Run installation
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

#### Arch Linux
```bash
# Install Docker
sudo pacman -S docker docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
newgrp docker

# Install Git
sudo pacman -S git curl

# Run installation
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

---

## 🔧 Manual Installation

If you prefer manual installation or the automatic script fails:

### 1. Clone Repository
```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
```

### 2. Run Update Script
```bash
# Interactive mode (asks for confirmation)
./update.sh

# Or automatic mode (no prompts)
./update.sh --yes
```

The script will:
- Initialize and update all submodules
- Create `.env` from example
- Generate secure encryption keys
- Configure permissions
- Build and start Docker containers
- Perform health checks

### 3. Wait for Build
First build takes 5-15 minutes. You'll see:
```
[+] Building omniroute...
[+] Building openclaw...
[+] Starting services...
```

---

## 🎯 Post-Installation

### 1. Access Services

After installation completes, access:

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| **OmniRoute Dashboard** | http://localhost:20128 | Username: `admin`<br>Password: Check `.env` file |
| **OpenClaw Gateway** | http://localhost:18789 | Token: Check `.env` file |

### 2. Change Default Passwords

**⚠️ IMPORTANT:** Change default passwords immediately!

#### OmniRoute Dashboard:
1. Open http://localhost:20128
2. Login with credentials from `.env`
3. Go to Settings → Security
4. Change admin password

#### OpenClaw Gateway:
1. Edit `.env` file:
   ```bash
   nano .env
   ```
2. Change `OPENCLAW_PASSWORD` to a strong password
3. Restart services:
   ```bash
   ./restart.sh
   ```

### 3. Configure API Keys

#### Add AI Provider Keys:
1. Open OmniRoute Dashboard
2. Go to "Providers" section
3. Add your API keys for:
   - OpenAI
   - Anthropic
   - Google Gemini
   - DeepSeek
   - Groq
   - xAI
   - etc.

### 4. Test the Setup

```bash
# Check service status
./status.sh

# View logs
./logs.sh

# Test API endpoint
curl http://localhost:20128/api/monitoring/health
```

---

## ✅ Verification

### Check Container Status
```bash
docker ps
```

You should see 3 running containers:
- `omniroute` (healthy)
- `openclaw` (healthy)
- `omniroute-redis` (healthy)

### Check Service Health
```bash
./healthcheck.sh
```

Expected output:
```
✓ OmniRoute is healthy
✓ OpenClaw is healthy
✓ Redis is healthy
✓ All services are running correctly
```

### Test API Endpoints

#### OmniRoute Health:
```bash
curl http://localhost:20128/api/monitoring/health
```

#### OpenClaw Health:
```bash
curl http://localhost:18789/healthz
```

### Check Logs
```bash
# All services
./logs.sh

# Specific service
docker logs omniroute
docker logs openclaw
docker logs omniroute-redis
```

---

## 🔍 Troubleshooting

### Installation Issues

#### "Docker not found"
Install Docker following platform-specific instructions above.

#### "Permission denied" errors
```bash
# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Or run with sudo (not recommended)
sudo ./update.sh
```

#### "Port already in use"
```bash
# Check what's using the port
sudo lsof -i :20128
sudo lsof -i :18789

# Change ports in .env file
nano .env
# Edit PORT and OPENCLAW_PORT
./restart.sh
```

#### "Out of disk space"
```bash
# Clean up Docker
./cleanup.sh

# Or manually
docker system prune -a --volumes
```

### Service Issues

#### Containers won't start
```bash
# Check logs
./logs.sh

# Check Docker resources (macOS/Windows)
# Increase memory to 8GB in Docker Desktop settings

# Restart services
./restart.sh
```

#### "Unhealthy" status
```bash
# Wait 2-3 minutes for services to initialize
# Then check logs
docker logs omniroute
docker logs openclaw

# If still unhealthy, restart
./restart.sh
```

#### Redis connection errors
```bash
# Check Redis is running
docker ps | grep redis

# Restart Redis
docker restart omniroute-redis

# Check Redis logs
docker logs omniroute-redis
```

### Performance Issues

#### Slow response times
```bash
# Check resource usage
./monitor.sh

# Increase Docker resources (macOS/Windows)
# Docker Desktop → Settings → Resources
# Memory: 8GB+, CPUs: 4+
```

#### High memory usage
```bash
# Check current usage
docker stats

# Restart services to clear cache
./restart.sh
```

---

## 📚 Additional Resources

- **Full Documentation:** [README.md](README.md)
- **Architecture:** [ARCHITECTURE.md](ARCHITECTURE.md)
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 🆘 Getting Help

If you encounter issues:

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/Den3112/OmniRoute-OpenClaw/issues)
3. Create a new issue with:
   - Your OS and version
   - Docker version (`docker --version`)
   - Error messages from logs
   - Output of `./status.sh`

---

## 🎉 Next Steps

After successful installation:

1. ✅ Change default passwords
2. ✅ Add your AI provider API keys
3. ✅ Read the [Dashboard Guide](DASHBOARD_GUIDE.md)
4. ✅ Explore the [Quick Start Guide](QUICKSTART.md)
5. ✅ Set up backups with `./backup.sh`

---

<div align="center">
Made with ❤️ for the AI developer community
</div>
