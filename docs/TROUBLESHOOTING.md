# 🛠 Troubleshooting Guide

Comprehensive troubleshooting guide for OmniRoute + OpenClaw installation and operation.

---

## 📋 Table of Contents

1. [Installation Issues](#-installation-issues)
2. [Docker Issues](#-docker-issues)
3. [Service Health Issues](#-service-health-issues)
4. [Network & Port Issues](#-network--port-issues)
5. [Performance Issues](#-performance-issues)
6. [Database Issues](#-database-issues)
7. [Security & Authentication Issues](#-security--authentication-issues)
8. [API & Integration Issues](#-api--integration-issues)
9. [Platform-Specific Issues](#-platform-specific-issues)
10. [Advanced Debugging](#-advanced-debugging)

---

## 🚨 Installation Issues

### Issue: "Docker not found" or "docker: command not found"

**Cause:** Docker is not installed or not in PATH.

**Solution:**
```bash
# Check if Docker is installed
which docker

# Install Docker (Ubuntu/Debian)
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker (macOS)
brew install --cask docker

# Verify installation
docker --version
docker compose version
```

---

### Issue: "Permission denied" when running Docker commands

**Cause:** User is not in the `docker` group.

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes immediately
newgrp docker

# Or logout and login again

# Verify
docker ps
```

**Alternative (not recommended):**
```bash
# Run with sudo
sudo ./update.sh
```

---

### Issue: "Failed to generate secure random value"

**Cause:** System lacks required utilities for secret generation.

**Solution:**
```bash
# Check available utilities
which openssl xxd od hexdump

# Install missing utilities (Ubuntu/Debian)
sudo apt install -y openssl coreutils

# Install missing utilities (macOS)
brew install openssl

# Retry installation
./update.sh --yes
```

---

### Issue: "Submodule 'OmniRoute' not found" or "Submodule 'openclaw' not found"

**Cause:** Repository was cloned without `--recursive` flag.

**Solution:**
```bash
# Initialize and update submodules
git submodule update --init --recursive

# Verify submodules
ls -la OmniRoute/
ls -la openclaw/

# Retry installation
./update.sh --yes
```

---

### Issue: "Low disk space" or "No space left on device"

**Cause:** Insufficient disk space for Docker images and build cache.

**Solution:**
```bash
# Check disk space
df -h

# Clean up Docker
./cleanup.sh

# Or manually
docker system prune -a --volumes

# Remove old images
docker image prune -a

# Check space again
df -h
```

**Minimum required:** 10GB free space  
**Recommended:** 20GB+ free space

---

## 🐋 Docker Issues

### Issue: Containers won't start

**Symptoms:**
- Containers exit immediately
- Status shows "Exited (1)" or "Restarting"

**Diagnosis:**
```bash
# Check container status
docker ps -a

# Check logs
./logs.sh

# Or specific container
docker logs omniroute
docker logs openclaw
docker logs omniroute-redis
```

**Common Solutions:**

#### 1. Port conflicts
```bash
# Check if ports are in use
sudo lsof -i :20128
sudo lsof -i :18789
sudo lsof -i :6379

# Change ports in .env
nano .env
# Edit PORT, OPENCLAW_PORT

# Restart
./restart.sh
```

#### 2. Insufficient resources
```bash
# Check Docker resources
docker stats

# Increase limits (macOS/Windows)
# Docker Desktop → Settings → Resources
# Memory: 8GB+, CPUs: 4+

# Restart Docker Desktop
```

#### 3. Corrupted volumes
```bash
# Stop containers
docker compose down

# Remove volumes
docker volume rm free-ai-aggregator_redis_data

# Restart
./update.sh --yes
```

---

### Issue: "Docker Compose not found" or "docker-compose: command not found"

**Cause:** Docker Compose plugin not installed.

**Solution:**

#### Modern Docker (Compose V2):
```bash
# Check if plugin exists
docker compose version

# Install plugin (Ubuntu/Debian)
sudo apt install docker-compose-plugin

# Install plugin (macOS)
# Included in Docker Desktop
```

#### Legacy Docker Compose V1:
```bash
# Install standalone docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify
docker-compose --version
```

---

### Issue: "Cannot connect to Docker daemon"

**Cause:** Docker daemon is not running.

**Solution:**

#### Linux:
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

#### macOS/Windows:
```bash
# Start Docker Desktop application
# Wait for whale icon to appear in menu bar/system tray

# Verify
docker ps
```

---

## 🏥 Service Health Issues

### Issue: Services show "unhealthy" status

**Symptoms:**
```bash
docker ps
# Shows (unhealthy) next to container names
```

**Diagnosis:**
```bash
# Check health status
docker inspect omniroute --format='{{.State.Health.Status}}'
docker inspect openclaw --format='{{.State.Health.Status}}'

# Check health logs
docker inspect omniroute --format='{{json .State.Health}}' | jq
```

**Solutions:**

#### 1. Wait for initialization
```bash
# Services need 1-3 minutes to start
# Wait and check again
sleep 180
docker ps
```

#### 2. Check logs for errors
```bash
./logs.sh

# Look for:
# - Port binding errors
# - Database connection errors
# - Missing environment variables
```

#### 3. Restart services
```bash
./restart.sh

# Or specific service
docker restart omniroute
docker restart openclaw
```

#### 4. Rebuild containers
```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

---

### Issue: OmniRoute returns 500 errors

**Cause:** Database issues, missing secrets, or configuration errors.

**Diagnosis:**
```bash
# Check OmniRoute logs
docker logs omniroute --tail 100

# Check for:
# - "STORAGE_ENCRYPTION_KEY is not set"
# - "Database error"
# - "Failed to connect to Redis"
```

**Solutions:**

#### 1. Check environment variables
```bash
# Verify .env file exists and has values
cat .env | grep -E "STORAGE_ENCRYPTION_KEY|JWT_SECRET|API_KEY_SECRET"

# Regenerate if missing
./update.sh --yes
```

#### 2. Check Redis connection
```bash
# Test Redis
docker exec omniroute-redis redis-cli ping
# Should return: PONG

# Check Redis logs
docker logs omniroute-redis
```

#### 3. Reset database
```bash
# Backup first
./backup.sh

# Stop services
docker compose down

# Remove data
rm -rf data/omniroute/*

# Restart
./update.sh --yes
```

---

### Issue: OpenClaw gateway not responding

**Symptoms:**
- `curl http://localhost:18789/healthz` times out
- Gateway shows as unhealthy

**Diagnosis:**
```bash
# Check OpenClaw logs
docker logs openclaw --tail 100

# Check if port is listening
sudo lsof -i :18789
```

**Solutions:**

#### 1. Check authentication
```bash
# Verify OPENCLAW_PASSWORD is set
grep OPENCLAW_PASSWORD .env

# Test with token
curl -H "Authorization: Bearer $(grep OPENCLAW_PASSWORD .env | cut -d= -f2)" \
  http://localhost:18789/healthz
```

#### 2. Check OmniRoute connection
```bash
# OpenClaw depends on OmniRoute
# Ensure OmniRoute is healthy first
docker ps | grep omniroute

# Check internal network
docker exec openclaw ping omniroute
```

#### 3. Restart with clean state
```bash
docker compose down
rm -rf data/openclaw/*
./restart.sh
```

---

## 🌐 Network & Port Issues

### Issue: "Port already in use" or "Address already in use"

**Diagnosis:**
```bash
# Check what's using the ports
sudo lsof -i :20128
sudo lsof -i :18789
sudo lsof -i :6379

# Or with netstat
sudo netstat -tulpn | grep -E "20128|18789|6379"
```

**Solutions:**

#### 1. Stop conflicting service
```bash
# Find process ID (PID) from lsof output
# Kill the process
sudo kill -9 <PID>

# Restart services
./restart.sh
```

#### 2. Change ports
```bash
# Edit .env file
nano .env

# Change:
PORT=20129              # OmniRoute (was 20128)
OPENCLAW_PORT=18790     # OpenClaw (was 18789)

# Restart
./restart.sh

# Access at new URLs:
# http://localhost:20129
# http://localhost:18790
```

---

### Issue: Cannot access services from browser

**Symptoms:**
- "Connection refused" in browser
- Services work with `curl` but not browser

**Solutions:**

#### 1. Check firewall
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow 20128/tcp
sudo ufw allow 18789/tcp

# Fedora/RHEL
sudo firewall-cmd --add-port=20128/tcp --permanent
sudo firewall-cmd --add-port=18789/tcp --permanent
sudo firewall-cmd --reload
```

#### 2. Check Docker network
```bash
# Verify network exists
docker network ls | grep ai_network

# Recreate network
docker compose down
docker network prune
docker compose up -d
```

#### 3. Try different browser
```bash
# Clear browser cache
# Try incognito/private mode
# Try different browser
```

---

## ⚡ Performance Issues

### Issue: Slow response times

**Symptoms:**
- API requests take >5 seconds
- Dashboard loads slowly
- High latency

**Diagnosis:**
```bash
# Check resource usage
./monitor.sh

# Or manually
docker stats

# Check system resources
htop  # or top
free -h
df -h
```

**Solutions:**

#### 1. Increase Docker resources (macOS/Windows)
```bash
# Docker Desktop → Settings → Resources
# Memory: 8GB+ (currently using)
# CPUs: 4+ cores
# Swap: 2GB+
# Disk: 60GB+

# Restart Docker Desktop
```

#### 2. Check Redis performance
```bash
# Redis stats
docker exec omniroute-redis redis-cli INFO stats

# Check memory usage
docker exec omniroute-redis redis-cli INFO memory

# If memory is full, increase maxmemory in docker-compose.yml
```

#### 3. Optimize database
```bash
# Check database size
du -sh data/omniroute/

# Vacuum SQLite database
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/omniroute.db');
db.pragma('vacuum');
db.close();
"
```

#### 4. Clear caches
```bash
# Restart services to clear memory caches
./restart.sh

# Clear Redis cache
docker exec omniroute-redis redis-cli FLUSHALL
```

---

### Issue: High memory usage

**Symptoms:**
- Containers using >4GB RAM
- System becomes unresponsive
- OOM (Out of Memory) errors

**Diagnosis:**
```bash
# Check memory usage
docker stats --no-stream

# Check system memory
free -h

# Check for memory leaks in logs
docker logs omniroute | grep -i "memory\|heap\|oom"
```

**Solutions:**

#### 1. Adjust memory limits
```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Adjust limits for omniroute:
deploy:
  resources:
    limits:
      memory: 3G  # Increase if needed

# Restart
docker compose down
docker compose up -d
```

#### 2. Enable swap (Linux)
```bash
# Check swap
swapon --show

# Create swap file (4GB)
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

#### 3. Restart services regularly
```bash
# Add to crontab for daily restart
crontab -e

# Add line:
0 3 * * * cd /path/to/free-ai-aggregator && ./restart.sh
```

---

### Issue: High CPU usage

**Symptoms:**
- CPU at 100%
- System fans running loud
- Slow performance

**Diagnosis:**
```bash
# Check CPU usage
docker stats

# Check processes inside container
docker exec omniroute ps aux --sort=-%cpu | head -10
```

**Solutions:**

#### 1. Limit CPU usage
```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Adjust CPU limits:
deploy:
  resources:
    limits:
      cpus: '2.0'  # Reduce if needed

# Restart
docker compose down
docker compose up -d
```

#### 2. Check for infinite loops
```bash
# Check logs for repeated errors
docker logs omniroute --tail 1000 | sort | uniq -c | sort -rn | head -20
```

---

## 💾 Database Issues

### Issue: "Database is locked" errors

**Cause:** SQLite database locked by another process.

**Solution:**
```bash
# Stop all services
docker compose down

# Check for stale locks
ls -la data/omniroute/*.db-*

# Remove lock files
rm -f data/omniroute/*.db-shm
rm -f data/omniroute/*.db-wal

# Restart
docker compose up -d
```

---

### Issue: Database corruption

**Symptoms:**
- "Database disk image is malformed"
- Services won't start
- Data loss

**Solution:**
```bash
# Stop services
docker compose down

# Backup corrupted database
cp data/omniroute/omniroute.db data/omniroute/omniroute.db.corrupted

# Try to recover
sqlite3 data/omniroute/omniroute.db ".recover" | sqlite3 data/omniroute/omniroute.db.recovered

# If recovery works, replace
mv data/omniroute/omniroute.db.recovered data/omniroute/omniroute.db

# If recovery fails, restore from backup
./restore.sh

# Or start fresh (data loss)
rm -rf data/omniroute/*
./update.sh --yes
```

---

### Issue: Redis connection errors

**Symptoms:**
- "Error: Redis connection failed"
- "ECONNREFUSED 127.0.0.1:6379"

**Diagnosis:**
```bash
# Check Redis is running
docker ps | grep redis

# Test Redis connection
docker exec omniroute-redis redis-cli ping

# Check Redis logs
docker logs omniroute-redis
```

**Solutions:**

#### 1. Restart Redis
```bash
docker restart omniroute-redis

# Wait 10 seconds
sleep 10

# Test connection
docker exec omniroute-redis redis-cli ping
```

#### 2. Check Redis configuration
```bash
# Check Redis memory
docker exec omniroute-redis redis-cli INFO memory

# Check Redis config
docker exec omniroute-redis redis-cli CONFIG GET maxmemory
```

#### 3. Recreate Redis container
```bash
docker compose down
docker volume rm free-ai-aggregator_redis_data
docker compose up -d
```

---

## 🔐 Security & Authentication Issues

### Issue: Cannot login to OmniRoute dashboard

**Symptoms:**
- "Invalid credentials" error
- Forgot password

**Solutions:**

#### 1. Check credentials in .env
```bash
# View current password
grep INITIAL_PASSWORD .env

# Default is: admin
```

#### 2. Reset admin password
```bash
# Stop services
docker compose down

# Edit .env
nano .env

# Change INITIAL_PASSWORD to new password
INITIAL_PASSWORD=your_new_password

# Remove database to force reset
rm -f data/omniroute/omniroute.db

# Restart (will recreate database)
docker compose up -d
```

#### 3. Check for password change
```bash
# If you changed password in dashboard, use new password
# Old INITIAL_PASSWORD won't work
```

---

### Issue: API key authentication fails

**Symptoms:**
- "Unauthorized" errors
- "Invalid API key"

**Solutions:**

#### 1. Check API key format
```bash
# API keys should start with "sk-omniroute-"
# Example: sk-omniroute-abc123def456
```

#### 2. Create new API key
```bash
# Login to dashboard
# Go to Settings → API Keys
# Create new key
# Copy and use immediately
```

#### 3. Check API_KEY_SECRET
```bash
# Verify secret is set
grep API_KEY_SECRET .env

# If missing, regenerate
./update.sh --yes
```

---

### Issue: OpenClaw token authentication fails

**Symptoms:**
- "Unauthorized" when accessing OpenClaw
- 401 errors

**Solutions:**

#### 1. Check token in .env
```bash
# View current token
grep OPENCLAW_PASSWORD .env
```

#### 2. Use token in requests
```bash
# Correct format
curl -H "Authorization: Bearer your_token_here" \
  http://localhost:18789/healthz

# Or as query parameter
curl "http://localhost:18789/healthz?token=your_token_here"
```

#### 3. Change token
```bash
# Edit .env
nano .env

# Change OPENCLAW_PASSWORD
OPENCLAW_PASSWORD=new_secure_token_here

# Restart
./restart.sh
```

---

## 🔌 API & Integration Issues

### Issue: AI provider API calls fail

**Symptoms:**
- "Provider not configured"
- "Invalid API key"
- 401/403 errors from providers

**Solutions:**

#### 1. Add provider API keys
```bash
# Login to OmniRoute dashboard
# Go to Providers section
# Add API keys for:
# - OpenAI
# - Anthropic
# - Google Gemini
# - etc.
```

#### 2. Test provider connection
```bash
# Test OpenAI
curl -X POST http://localhost:20128/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your_omniroute_api_key" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello"}]
  }'
```

#### 3. Check provider status
```bash
# Check logs for provider errors
docker logs omniroute | grep -i "provider\|api key"
```

---

### Issue: Streaming responses not working

**Symptoms:**
- Responses arrive all at once
- No streaming chunks
- SSE connection fails

**Solutions:**

#### 1. Check client supports SSE
```bash
# Test with curl
curl -N -H "Accept: text/event-stream" \
  -H "Authorization: Bearer your_key" \
  -X POST http://localhost:20128/v1/chat/completions \
  -d '{"model":"gpt-4","messages":[{"role":"user","content":"Count to 10"}],"stream":true}'
```

#### 2. Check nginx/proxy configuration
```bash
# If using reverse proxy, ensure:
# - proxy_buffering off;
# - proxy_cache off;
# - chunked_transfer_encoding on;
```

---

## 🖥 Platform-Specific Issues

### macOS Issues

#### Issue: "Docker Desktop is not running"
```bash
# Start Docker Desktop
open -a Docker

# Wait for startup (whale icon in menu bar)
sleep 30

# Verify
docker ps
```

#### Issue: Slow performance on macOS
```bash
# Use VirtioFS instead of gRPC FUSE
# Docker Desktop → Settings → General
# Enable "VirtioFS" under file sharing

# Increase resources
# Docker Desktop → Settings → Resources
# Memory: 8GB+
# CPUs: 4+
```

---

### Windows WSL2 Issues

#### Issue: "Cannot connect to Docker daemon" in WSL2
```bash
# Ensure Docker Desktop WSL2 integration is enabled
# Docker Desktop → Settings → Resources → WSL Integration
# Enable your Ubuntu distribution

# Restart WSL2
wsl --shutdown
# Reopen Ubuntu
```

#### Issue: Slow file access in WSL2
```bash
# Move project to WSL2 filesystem (not /mnt/c/)
cd ~
git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
cd OmniRoute-OpenClaw
./update.sh --yes
```

---

### Linux Issues

#### Issue: SELinux blocking Docker
```bash
# Check SELinux status
getenforce

# Temporarily disable (not recommended for production)
sudo setenforce 0

# Or configure SELinux for Docker
sudo setsebool -P container_manage_cgroup on
```

#### Issue: AppArmor blocking Docker
```bash
# Check AppArmor status
sudo aa-status

# Reload Docker profile
sudo apparmor_parser -r /etc/apparmor.d/docker
```

---

## 🔬 Advanced Debugging

### Enable debug logging

#### OmniRoute:
```bash
# Edit docker-compose.yml
nano docker-compose.yml

# Add to omniroute environment:
- DEBUG=*
- LOG_LEVEL=debug

# Restart
docker compose down
docker compose up -d

# View debug logs
docker logs -f omniroute
```

#### OpenClaw:
```bash
# Add to openclaw environment:
- NODE_ENV=development
- DEBUG=openclaw:*

# Restart and view logs
docker compose down
docker compose up -d
docker logs -f openclaw
```

---

### Inspect container internals

```bash
# Enter container shell
docker exec -it omniroute sh
docker exec -it openclaw sh

# Check processes
ps aux

# Check network
netstat -tulpn

# Check disk usage
df -h

# Check environment
env | sort

# Exit
exit
```

---

### Network debugging

```bash
# Test internal network connectivity
docker exec omniroute ping redis
docker exec openclaw ping omniroute

# Check DNS resolution
docker exec omniroute nslookup redis
docker exec openclaw nslookup omniroute

# Test port connectivity
docker exec omniroute nc -zv redis 6379
docker exec openclaw nc -zv omniroute 20128
```

---

### Performance profiling

```bash
# CPU profiling
docker stats --no-stream

# Memory profiling
docker exec omniroute node -e "console.log(process.memoryUsage())"

# Heap snapshot (Node.js)
docker exec omniroute node --expose-gc -e "
  global.gc();
  const used = process.memoryUsage();
  console.log(JSON.stringify(used, null, 2));
"
```

---

## 🆘 Still Having Issues?

If none of the above solutions work:

### 1. Collect diagnostic information
```bash
# Run status check
./status.sh > status.txt

# Collect logs
./logs.sh > logs.txt

# System information
uname -a > system.txt
docker version >> system.txt
docker compose version >> system.txt
free -h >> system.txt
df -h >> system.txt
```

### 2. Search existing issues
- [GitHub Issues](https://github.com/Den3112/OmniRoute-OpenClaw/issues)
- Search for error messages
- Check closed issues

### 3. Create new issue
Include:
- Operating system and version
- Docker version
- Error messages from logs
- Output of `./status.sh`
- Steps to reproduce
- What you've already tried

### 4. Community support
- GitHub Discussions
- Discord server (if available)
- Stack Overflow with tag `omniroute` or `openclaw`

---

## 📚 Additional Resources

- [Installation Guide](INSTALL.md)
- [Architecture Documentation](ARCHITECTURE.md)
- [README](README.md)
- [Contributing Guide](CONTRIBUTING.md)

---

<div align="center">
Made with ❤️ for the AI developer community
</div>
