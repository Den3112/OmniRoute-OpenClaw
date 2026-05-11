# 🚀 Quick Start Guide

## One-Command Installation

The fastest way to get started:

```bash
curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash
```

That's it! Wait 10-15 minutes and everything will be ready.

---

## What Gets Installed?

- **OmniRoute**: AI API aggregator and load balancer
- **OpenClaw**: Agentic AI gateway
- **Redis**: High-performance caching layer

---

## After Installation

### 1. Access the Services

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| OmniRoute Dashboard | http://localhost:20128 | admin / admin |
| OpenClaw Gateway | http://localhost:18789 | Token in `.env` file |

### 2. Change Default Passwords

⚠️ **IMPORTANT**: Change the default passwords immediately!

1. Log into OmniRoute Dashboard
2. Go to Settings → Security
3. Change admin password
4. Update API keys

### 3. Configure Your AI Providers

1. Open OmniRoute Dashboard
2. Navigate to "Providers"
3. Add your API keys:
   - OpenAI
   - Anthropic Claude
   - Google Gemini
   - etc.

---

## Common Commands

```bash
# Navigate to installation directory
cd ~/omniroute-openclaw

# Restart all services
./restart.sh

# Check service health
./healthcheck.sh

# View logs
docker compose logs -f

# Stop all services
docker compose down

# Start all services
docker compose up -d
```

---

## Troubleshooting

### Services not starting?

```bash
# Check status
docker ps -a

# View logs
docker logs omniroute
docker logs openclaw
docker logs omniroute-redis

# Run health check
./healthcheck.sh
```

### Port conflicts?

Edit `.env` file and change:
```bash
PORT=20128          # OmniRoute port
OPENCLAW_PORT=18789 # OpenClaw port
```

Then restart:
```bash
./restart.sh
```

### Need to rebuild?

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

## Next Steps

1. ✅ Configure AI provider API keys
2. ✅ Set up load balancing rules
3. ✅ Configure rate limiting
4. ✅ Set up monitoring and alerts
5. ✅ Read full documentation: [ARCHITECTURE.md](ARCHITECTURE.md)

---

## Getting Help

- 📖 Full documentation: [README.md](README.md)
- 🏗️ Architecture guide: [ARCHITECTURE.md](ARCHITECTURE.md)
- 🐛 Report issues: [GitHub Issues](https://github.com/Den3112/OmniRoute-OpenClaw/issues)

---

## Uninstall

```bash
cd ~/omniroute-openclaw
docker compose down -v
cd ..
rm -rf omniroute-openclaw
```

---

**Enjoy your AI infrastructure!** 🎉
