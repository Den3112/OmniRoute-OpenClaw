# OmniRoute + OpenClaw (All-in-One Docker)

Professional, pre-configured environment for running **OmniRoute** (API Aggregator) and **OpenClaw** (Agentic AI Gateway) together.

## 🚀 Quick Start (One-Click)

1. **Clone the repository**:
   ```bash
   git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
   cd OmniRoute-OpenClaw
   ```

2. **Run the installer**:
   ```bash
   chmod +x update.sh
   ./update.sh
   ```

**That's it!** The script will:
- Initialize all submodules.
- Generate secure random keys for your deployment.
- Configure `.env` automatically.
- Start all services in Docker.

## 📍 Services

- **OmniRoute Dashboard**: [http://localhost:20128](http://localhost:20128) (Default login: `admin` / `admin`)
- **OpenClaw Gateway**: [http://localhost:18789](http://localhost:18789)

## 🔄 Updates

To update both OmniRoute and OpenClaw to their latest versions, just run:
```bash
./update.sh
```

## 🛠 Features

- **Automated Security**: Automatic generation of `JWT_SECRET`, `API_KEY_SECRET`, and `STORAGE_ENCRYPTION_KEY`.
- **Redis Caching**: Built-in Redis for high-performance session and data management.
- **Log Management**: Automatic log rotation (10MB max per file, 3 files max) to prevent disk bloat.
- **Health Monitoring**: Robust healthchecks ensure services are only used when ready.
- **Isolated Network**: Services communicate over a private Docker bridge network.

## 📄 License
MIT
