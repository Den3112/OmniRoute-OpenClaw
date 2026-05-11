# OmniRoute + OpenClaw (All-in-One Docker)

![Project Banner](docs/images/banner.png)

<div align="center">

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Docker](https://img.shields.io/badge/Docker-Supported-blue.svg?logo=docker)](https://www.docker.com/)
[![Version](https://img.shields.io/badge/Version-1.2.0-green.svg)](https://github.com/Den3112/OmniRoute-OpenClaw)
[![Status](https://img.shields.io/badge/Status-Stable-brightgreen.svg)]()

**Professional environment for running OmniRoute and OpenClaw in a unified Docker container.**
*API Aggregator + Agentic AI Gateway — everything you need to work with LLMs in one place.*

[Quick Start](#-quick-start) • [Features](#-features) • [Architecture](#-architecture) • [Services](#-services) • [Documentation](#-documentation)

</div>

---

## 📖 Documentation
- [📥 **Installation Guide**](INSTALL.md)
- [🛠 **Troubleshooting**](TROUBLESHOOTING.md)
- [🏗 **Architecture**](ARCHITECTURE.md)

---

## ✨ Features

### Core Features
- **Unified API Gateway**: Single endpoint for all your AI models (Anthropic, OpenAI, Gemini, etc.).
- **Advanced Load Balancing**: Intelligent routing between multiple providers.
- **Token & Key Management**: Securely manage and rotate your API keys.
- **Real-time Monitoring**: Integrated health checks and performance tracking.
- **Easy Deployment**: Docker-based setup with a one-click installer.
- **Privacy First**: All configurations and logs stay on your server.

### Security Features (NEW! 🔐)
- **Automatic Password Generation**: Unique passwords generated on installation
- **Secret Rotation**: Built-in tool for rotating all security credentials
- **Pre-commit Hooks**: Automatic checks to prevent committing secrets
- **CI/CD Testing**: Automated testing on multiple platforms

### Developer Experience (NEW! 🛠️)
- **Comprehensive Documentation**: Installation guides in English and Russian
- **Troubleshooting Guide**: Solutions for common issues
- **Local Testing**: Test installation before deploying
- **Management Scripts**: Easy-to-use scripts for all operations

---

## 💻 System Requirements
| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 2 Cores | 4+ Cores |
| RAM | 4 GB | 8 GB+ |
| Disk | 10 GB | 20 GB+ (SSD) |
| OS | Linux / macOS / WSL2 | Ubuntu 22.04+ |

---

## 🚀 Quick Start

### ⚡ One-Command Installation (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

**That's it!** The script will automatically:
- Clone the repository with all submodules
- Generate secure encryption keys
- Build and start all Docker containers
- Verify all services are healthy

### 📦 Manual Installation

```bash
# 1. Clone with submodules
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw

# 2. Run automatic installer
./update.sh --yes

# Or interactive mode
./update.sh
```

**What the script does:**
- Initializes and updates all submodules
- Creates `.env` from example and generates secure keys
- Configures permissions and starts Docker containers
- Performs health checks on all services
- Auto-recovers from common issues

---

## 🏗 Architecture

The project uses a microservices architecture, isolated within a private Docker network.

```mermaid
graph TD
    User([User]) -->|HTTP| OR_Dash[OmniRoute Dashboard :20128]
    User -->|API Requests| OC_Gate[OpenClaw Gateway :18789]
    
    subgraph Docker Network
        OC_Gate -->|Internal API| OR_Core[OmniRoute Core]
        OR_Core -->|Cache| Redis[(Redis)]
        OR_Core -->|Storage| DB[(SQLite / Persistent Data)]
    end
    
    OR_Core -->|External API| Providers{AI Providers}
    Providers --> OpenAI[OpenAI]
    Providers --> Anthropic[Anthropic]
    Providers --> Google[Google Gemini]
```

---

## 📍 Services

After startup, the following endpoints will be available:

| Service | Address | Credentials |
| :--- | :--- | :--- |
| **OmniRoute Dashboard** | [http://localhost:20128](http://localhost:20128) | Auto-generated during installation |
| **OpenClaw Gateway** | [http://localhost:18789](http://localhost:18789) | Token auto-generated |
| **Redis** | `redis://localhost:6379` | (Internal access) |

> [!IMPORTANT]
> 🔐 **Enhanced Security!** Starting from version 2.0, unique passwords are automatically generated during installation.
> Passwords are displayed at the end of installation. Save them in a secure location!

---

## 🛠 Features

- **🔐 Automatic Security**: The `update.sh` script generates unique encryption keys on first run.
- **🚀 High Performance**: Redis integration provides instant caching of sessions and responses.
- **📊 Smart Logs**: Automatic log rotation (max 10MB per file) protects your disk from overflow.
- **🔄 Easy Updates**: To update both projects to the latest versions, simply run `./update.sh` again.
- **📂 Data Migration**: The script automatically picks up data from old versions (in `$HOME/.omniroute`), if they exist.
- **🏥 Automatic Recovery**: Built-in monitoring and automatic service recovery system.
- **⚡ Zero-config Installation**: One command for complete installation without questions.

---

## 🔧 Management

### Basic Commands
```bash
# Restart all services
./restart.sh

# Health check and automatic recovery
./healthcheck.sh

# Status monitoring
./monitor.sh

# View logs
./logs.sh

# Full update
./update.sh --yes
```

### Security (NEW! 🔐)
```bash
# Rotate all secrets
./rotate-secrets.sh

# Rotate passwords only
./rotate-secrets.sh --passwords

# Rotate encryption keys only
./rotate-secrets.sh --keys
```

### Backup
```bash
# Create backup
./backup.sh

# Restore from backup
./restore.sh
```

### Testing
```bash
# Local installation testing
./test-install.sh

# Testing with verbose output
./test-install.sh --verbose

# Testing without cleanup
./test-install.sh --keep
```

---

## ⚙️ Configuration

All settings are stored in the `.env` file. Main variables:

- `STORAGE_ENCRYPTION_KEY`: Key for encrypting data in the database.
- `JWT_SECRET`: Secret for user authorization.
- `OPENCLAW_PASSWORD`: Password for accessing the OpenClaw gateway.
- `INITIAL_PASSWORD`: OmniRoute administrator password on first startup.

---

## 📄 License

This project is distributed under the **MIT** license. See the [LICENSE](LICENSE) file for details.

---

<div align="center">
Created with ❤️ for the AI developer community.
</div>
