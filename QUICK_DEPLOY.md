# 🚀 Quick Deployment Guide

**Last Updated**: 2026-05-11

---

## ⚡ One-Command Installation

The fastest way to get started:

```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/bootstrap.sh | bash
```

**What it does:**
- ✅ Clones repository
- ✅ Pulls Docker images (3-5 minutes)
- ✅ Generates secure secrets
- ✅ Configures OpenCode MCP integration
- ✅ Enables Memory Management
- ✅ Starts all services

**Time**: ~5-7 minutes total

---

## 📋 Manual Installation

If you prefer more control:

### Step 1: Clone Repository

```bash
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
```

### Step 2: Choose Deployment Mode

#### Fast Mode (Recommended) ⚡

Uses pre-built Docker images from GitHub Container Registry:

```bash
# Generate secrets
./scripts/generate-secrets.sh

# Pull images and start
docker compose -f docker-compose.fast.yml up -d

# Configure OpenCode MCP
./scripts/setup-opencode-mcp.sh

# Enable Memory Management
./scripts/enable-memory.sh
```

**Time**: ~3-5 minutes

#### Build Mode 🔨

Builds images locally (slower but works offline):

```bash
# Generate secrets
./scripts/generate-secrets.sh

# Build and start
docker compose up -d --build

# Configure OpenCode MCP
./scripts/setup-opencode-mcp.sh

# Enable Memory Management
./scripts/enable-memory.sh
```

**Time**: ~15-20 minutes

---

## 🎯 What You Get

### Services

| Service | URL | Description |
|---------|-----|-------------|
| **OmniRoute Dashboard** | http://localhost:20128 | Main dashboard and API |
| **OpenClaw Gateway** | http://localhost:18789 | AI gateway interface |
| **Memory Dashboard** | http://localhost:20128/dashboard/memory | Memory Management UI |

### Features

- ✅ **160+ AI Providers** - OpenAI, Anthropic, Gemini, DeepSeek, and more
- ✅ **Memory Management** - Automatic context preservation between sessions
- ✅ **OpenCode Integration** - MCP server with 30+ tools
- ✅ **Smart Routing** - Intelligent provider selection and fallback
- ✅ **Cost Tracking** - Real-time usage and cost monitoring
- ✅ **Rate Limiting** - Built-in rate limit management
- ✅ **Caching** - Semantic and prompt caching

---

## 🔐 Default Credentials

**OmniRoute:**
- Username: `admin`
- Password: `admin`

**OpenClaw:**
- Check `.env` file for `OPENCLAW_PASSWORD`

⚠️ **IMPORTANT**: Change default passwords after first login!

---

## 💡 Quick Start Guide

### 1. Access Dashboard

Open http://localhost:20128 in your browser and login with default credentials.

### 2. Configure API Keys

Navigate to **Settings** → **Providers** and add your API keys for the providers you want to use.

### 3. Test Memory Management

Open http://localhost:20128/dashboard/memory to see the Memory Management interface.

### 4. Integrate with OpenCode

If you use OpenCode:

```bash
# Restart OpenCode to load MCP server
opencode

# Test MCP tools
"Какие MCP инструменты доступны?"

# Test memory
"Запомни, что этот проект называется OmniRoute"
```

---

## 🛠️ Common Commands

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f omniroute
docker compose logs -f openclaw
```

### Restart Services

```bash
# All services
docker compose restart

# Specific service
docker compose restart omniroute
```

### Stop Services

```bash
docker compose down
```

### Update to Latest Version

```bash
git pull --rebase
git submodule update --init --recursive
docker compose pull
docker compose up -d
```

---

## 🔧 Deployment Modes Comparison

| Feature | Fast Mode | Build Mode |
|---------|-----------|------------|
| **Speed** | 3-5 minutes | 15-20 minutes |
| **Internet Required** | Yes (pull images) | Yes (dependencies) |
| **Disk Space** | ~8 GB | ~10 GB |
| **Customization** | Limited | Full |
| **Offline Support** | No | Partial |
| **Recommended For** | Production, Quick Testing | Development, Custom Builds |

---

## 📊 System Requirements

### Minimum

- **CPU**: 2 cores
- **RAM**: 4 GB
- **Disk**: 10 GB free space
- **OS**: Linux, macOS, or WSL2

### Recommended

- **CPU**: 4+ cores
- **RAM**: 8 GB+
- **Disk**: 20 GB+ (SSD)
- **OS**: Ubuntu 22.04+

---

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker ps

# Check logs for errors
docker compose logs

# Restart Docker daemon
sudo systemctl restart docker  # Linux
```

### Can't Pull Images

If you can't access GitHub Container Registry:

```bash
# Use build mode instead
docker compose up -d --build
```

### Memory Management Not Working

```bash
# Re-enable Memory Management
./scripts/enable-memory.sh

# Check status
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const result = db.prepare('SELECT value FROM key_value WHERE namespace = ? AND key = ?')
  .get('settings', 'memoryEnabled');
console.log('Memory enabled:', result.value);
"
```

### OpenCode MCP Not Working

```bash
# Reconfigure MCP
./scripts/setup-opencode-mcp.sh

# Check configuration
cat ~/.config/opencode/mcp-servers.json

# Restart OpenCode
```

---

## 🔄 Update Guide

### Update from Git

```bash
cd ~/omniroute-openclaw  # or your installation directory
git pull --rebase
git submodule update --init --recursive
```

### Update Docker Images

```bash
# Fast mode
docker compose -f docker-compose.fast.yml pull
docker compose -f docker-compose.fast.yml up -d

# Or regular mode
docker compose pull
docker compose up -d
```

### Update Scripts

```bash
# Make sure scripts are executable
chmod +x scripts/*.sh bootstrap.sh

# Re-run setup if needed
./scripts/setup-opencode-mcp.sh
./scripts/enable-memory.sh
```

---

## 📚 Additional Documentation

- **[README.md](README.md)** - Full project documentation
- **[INTEGRATION_COMPLETE.md](INTEGRATION_COMPLETE.md)** - OpenCode Memory integration
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System architecture
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Detailed troubleshooting guide

---

## 🎓 Advanced Usage

### Custom Port Configuration

Edit `.env` file:

```bash
PORT=20128              # OmniRoute port
OPENCLAW_PORT=18789     # OpenClaw port
```

Then restart:

```bash
docker compose down
docker compose up -d
```

### Enable Debug Logging

Edit `.env` file:

```bash
NODE_ENV=development
DEBUG=omniroute:*
```

### Custom Memory Settings

Access http://localhost:20128/dashboard/settings and navigate to **Memory Settings**:

- **Max Tokens**: 2000 (default)
- **Retention Days**: 30 (default)
- **Strategy**: hybrid (recommended)

---

## 🌟 Features Overview

### Memory Management

Automatically saves and retrieves context between sessions:

- **4 Memory Types**: factual, episodic, procedural, semantic
- **3 Search Strategies**: exact, semantic, hybrid
- **FTS5 Full-Text Search**: Fast and accurate
- **Dashboard UI**: Visual memory management

### OpenCode Integration

MCP server with 30+ tools:

- **Memory Tools** (3): search, add, clear
- **Skills Tools** (4): list, enable, execute, executions
- **Routing Tools** (20+): health, combos, quota, cost reports
- **Compression Tools** (5): status, configure, stats

### Smart Routing

Intelligent request routing:

- **13 Strategies**: priority, weighted, round-robin, cost-optimized, etc.
- **Automatic Fallback**: Seamless provider switching
- **Health Monitoring**: Circuit breakers and rate limit tracking
- **Cost Optimization**: Budget guards and cost tracking

---

## 💬 Support

### Documentation

- **Quick Deploy**: This file
- **Full Docs**: [README.md](README.md)
- **Integration**: [INTEGRATION_COMPLETE.md](INTEGRATION_COMPLETE.md)

### Logs

```bash
# View all logs
docker compose logs -f

# View specific service
docker compose logs -f omniroute
```

### Health Check

```bash
# OmniRoute
curl http://localhost:20128/api/health

# OpenClaw
curl http://localhost:18789/healthz
```

---

## ✅ Post-Installation Checklist

- [ ] Services are running (`docker ps`)
- [ ] OmniRoute dashboard accessible (http://localhost:20128)
- [ ] Default password changed
- [ ] API keys configured for providers
- [ ] Memory Management enabled
- [ ] OpenCode MCP configured (if using OpenCode)
- [ ] Tested basic functionality

---

## 🎉 You're Ready!

Your OmniRoute + OpenClaw installation is complete and ready to use.

**Next Steps:**
1. Login to dashboard: http://localhost:20128
2. Configure your API keys
3. Start using AI providers through unified gateway
4. Explore Memory Management features

**Enjoy! 🚀**

---

**Created**: 2026-05-11  
**Version**: 1.0.0  
**Status**: Production Ready
