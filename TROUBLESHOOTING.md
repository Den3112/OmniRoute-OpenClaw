# 🛠 Troubleshooting Guide

This document provides solutions for common issues encountered during installation and operation.

## 📋 Table of Contents
1. [Installation Failures](#-installation-failures)
2. [Docker Issues](#-docker-issues)
3. [Permission Errors](#-permission-errors)
4. [Port Conflicts](#-port-conflicts)
5. [Submodule Issues](#-submodule-issues)
6. [Performance & Memory](#-performance--memory)

---

## 📥 Installation Failures

### Secret Generation Failed
**Error:** `Failed to generate secure random value`
- **Cause:** Your system lacks `openssl`, `xxd`, `od`, or `hexdump`.
- **Solution:** Install one of these utilities. On Ubuntu: `sudo apt install openssl`.

### Disk Space Error
**Error:** `Low disk space`
- **Cause:** The project requires ~10GB for Docker images and build cache.
- **Solution:** Run `./cleanup.sh` or remove unused Docker images/containers with `docker system prune -a`.

---

## 🐋 Docker Issues

### Containers won't start
- **Command:** `./logs.sh`
- **Solution:** Check the logs for specific errors. Common causes include insufficient memory or port conflicts.

### "Docker Compose not found"
- **Cause:** You have Docker installed but not the Compose plugin.
- **Solution:** Follow the [official installation guide](https://docs.docker.com/compose/install/).

---

## 🔒 Permission Errors

### "Permission denied" when accessing volumes
- **Cause:** Docker is running with different UID/GID than the host directory owner.
- **Solution:** The `update.sh` script attempts to fix this automatically. If it fails, try:
  ```bash
  sudo chown -R 1000:1000 ./data/openclaw
  sudo chmod -R 755 ./data/openclaw
  ```

---

## 🔌 Port Conflicts

### Port 20128 or 18789 is already in use
- **Check:** `lsof -i :20128` or `netstat -tulpn | grep 20128`
- **Solution:** Stop the service using the port or change the port in `.env` (for OmniRoute) or `docker-compose.yml` (for OpenClaw).

---

## 📦 Submodule Issues

### "OmniRoute missing" or "OpenClaw missing"
- **Cause:** Repository was cloned without `--recursive` or submodules failed to initialize.
- **Solution:** Run the following command manually:
  ```bash
  git submodule update --init --recursive
  ```

---

## 🚀 Performance & Memory

### Services are slow or crashing
- **Cause:** Insufficient RAM allocated to Docker.
- **Solution:** 
  - On macOS/Windows: Increase memory limit in Docker Desktop settings (minimum 4GB, 8GB recommended).
  - On Linux: Ensure swap is enabled if RAM is low.

### High CPU usage during build
- **Solution:** The initial build is resource-intensive. It will stabilize once containers are running. Use `./status.sh` to monitor resource usage.

---

## 🆘 Still having issues?

1. Run `./status.sh` and check for red items.
2. Run `./logs.sh` to see error messages.
3. Check the [GitHub Issues](https://github.com/Den3112/OmniRoute-OpenClaw/issues) for similar problems.
