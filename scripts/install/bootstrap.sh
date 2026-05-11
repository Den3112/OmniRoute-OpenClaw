#!/bin/bash
# bootstrap.sh - One-Command Installer for OmniRoute + OpenClaw
# Usage: curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/bootstrap.sh | bash
#
# This script provides a complete automated setup:
# - Clones repository
# - Pulls Docker images (fast deployment)
# - Generates secure secrets
# - Configures OpenCode MCP integration
# - Enables Memory Management
# - Starts all services

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_step() { echo ""; echo -e "${BLUE}==>${NC} $1"; }

# Start timer
START_TIME=$(date +%s)

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     🚀 OmniRoute + OpenClaw Bootstrap Installer           ║"
echo "║        Fast Deployment with Memory Management             ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    print_error "Do not run this script as root!"
    echo "   Run as regular user: curl -fsSL ... | bash"
    exit 1
fi

# Detect installation directory
INSTALL_DIR="${INSTALL_DIR:-$HOME/omniroute-openclaw}"
REPO_URL="https://github.com/Den3112/OmniRoute-OpenClaw.git"

# Detect project root (if running from existing installation)
if [ -f "$(dirname "$0")/docker-compose.yml" ]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
    print_info "Running from existing installation: $PROJECT_ROOT"
else
    PROJECT_ROOT="$INSTALL_DIR"
    print_info "Installation directory: $INSTALL_DIR"
fi

# ============================================================================
# 1. CHECK PREREQUISITES
# ============================================================================

print_step "Checking prerequisites..."

# Check Git
if ! command -v git >/dev/null 2>&1; then
    print_error "Git is not installed"
    echo ""
    echo "Install Git first:"
    echo "  Ubuntu/Debian: sudo apt-get install git"
    echo "  CentOS/RHEL:   sudo yum install git"
    echo "  macOS:         brew install git"
    exit 1
fi
print_success "Git found"

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed"
    echo ""
    echo "Install Docker first:"
    echo "  https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker found"

# Check Docker Compose
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    print_error "Docker Compose not found"
    echo ""
    echo "Install Docker Compose:"
    echo "  https://docs.docker.com/compose/install/"
    exit 1
fi
print_success "Docker Compose found"

# Check OpenSSL for secret generation
if ! command -v openssl >/dev/null 2>&1; then
    print_warning "OpenSSL not found - will use fallback for secret generation"
fi

# ============================================================================
# 2. CLONE OR UPDATE REPOSITORY
# ============================================================================

print_step "Setting up repository..."

if [ -d "$INSTALL_DIR" ]; then
    print_info "Directory exists, updating..."
    cd "$INSTALL_DIR"
    PROJECT_ROOT="$(pwd)"
    
    # Check if it's a git repository
    if [ -d .git ]; then
        git pull --rebase 2>/dev/null || print_warning "Could not update repository"
        git submodule update --init --recursive 2>/dev/null || true
    else
        print_error "Directory exists but is not a git repository"
        echo "   Please remove $INSTALL_DIR and try again"
        exit 1
    fi
else
    print_info "Cloning repository..."
    git clone --recursive "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    PROJECT_ROOT="$(pwd)"
fi

print_success "Repository ready at $PROJECT_ROOT"

# ============================================================================
# 3. GENERATE SECRETS
# ============================================================================

print_step "Generating secure secrets..."

if [ -f scripts/generate-secrets.sh ]; then
    chmod +x scripts/generate-secrets.sh
    ./scripts/generate-secrets.sh
else
    print_warning "generate-secrets.sh not found, creating .env manually"
    
    if [ ! -f .env ]; then
        cp .env.example .env 2>/dev/null || touch .env
        
        # Generate secrets
        if command -v openssl >/dev/null 2>&1; then
            STORAGE_KEY=$(openssl rand -hex 32)
            JWT_SECRET=$(openssl rand -hex 32)
            API_SECRET=$(openssl rand -hex 32)
            OPENCLAW_PASS=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
        else
            # Fallback to /dev/urandom
            STORAGE_KEY=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
            JWT_SECRET=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
            API_SECRET=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
            OPENCLAW_PASS=$(cat /dev/urandom | tr -dc 'A-Za-z0-9' | fold -w 16 | head -n 1)
        fi
        
        # Update .env
        echo "STORAGE_ENCRYPTION_KEY=$STORAGE_KEY" >> .env
        echo "JWT_SECRET=$JWT_SECRET" >> .env
        echo "API_KEY_SECRET=$API_SECRET" >> .env
        echo "OPENCLAW_PASSWORD=$OPENCLAW_PASS" >> .env
        echo "INITIAL_PASSWORD=admin" >> .env
    fi
    
    print_success "Secrets generated"
fi

# ============================================================================
# 4. PULL DOCKER IMAGES (FAST MODE)
# ============================================================================

print_step "Pulling Docker images..."
print_info "This may take 3-5 minutes depending on your internet speed"

# Try to pull images
if $DOCKER_COMPOSE -f docker-compose.fast.yml pull 2>/dev/null; then
    print_success "Docker images pulled successfully"
    USE_FAST_MODE=true
else
    print_warning "Could not pull images from registry"
    print_info "Will build locally (this will take longer)"
    USE_FAST_MODE=false
fi

# ============================================================================
# 5. START SERVICES
# ============================================================================

print_step "Starting services..."

if [ "$USE_FAST_MODE" = true ]; then
    $DOCKER_COMPOSE -f docker-compose.fast.yml up -d
else
    $DOCKER_COMPOSE up -d --build
fi

print_success "Services started"

# ============================================================================
# 6. WAIT FOR SERVICES TO BE READY
# ============================================================================

print_step "Waiting for services to be ready..."

# Wait for OmniRoute
print_info "Waiting for OmniRoute (max 60s)..."
WAITED=0
while [ $WAITED -lt 60 ]; do
    if curl -s http://localhost:20128/api/health > /dev/null 2>&1; then
        print_success "OmniRoute is ready"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

if [ $WAITED -ge 60 ]; then
    print_warning "OmniRoute took longer than expected to start"
    print_info "Check logs: docker compose logs omniroute"
fi

echo ""

# ============================================================================
# 7. CONFIGURE OPENCODE MCP
# ============================================================================

print_step "Configuring OpenCode MCP integration..."

if [ -f scripts/setup-opencode-mcp.sh ]; then
    chmod +x scripts/setup-opencode-mcp.sh
    ./scripts/setup-opencode-mcp.sh
else
    print_warning "setup-opencode-mcp.sh not found, skipping OpenCode configuration"
fi

# ============================================================================
# 8. ENABLE MEMORY MANAGEMENT
# ============================================================================

print_step "Enabling Memory Management..."

if [ -f scripts/enable-memory.sh ]; then
    chmod +x scripts/enable-memory.sh
    ./scripts/enable-memory.sh
else
    print_warning "enable-memory.sh not found, skipping Memory Management setup"
fi

# ============================================================================
# 9. FINAL CHECKS
# ============================================================================

print_step "Running final checks..."

# Check if containers are running
OMNIROUTE_RUNNING=$(docker ps | grep -c omniroute || true)
OPENCLAW_RUNNING=$(docker ps | grep -c openclaw || true)
REDIS_RUNNING=$(docker ps | grep -c omniroute-redis || true)

if [ "$OMNIROUTE_RUNNING" -gt 0 ]; then
    print_success "OmniRoute container is running"
else
    print_error "OmniRoute container is not running"
fi

if [ "$OPENCLAW_RUNNING" -gt 0 ]; then
    print_success "OpenClaw container is running"
else
    print_warning "OpenClaw container is not running (may still be starting)"
fi

if [ "$REDIS_RUNNING" -gt 0 ]; then
    print_success "Redis container is running"
else
    print_error "Redis container is not running"
fi

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

# ============================================================================
# 10. SUCCESS MESSAGE
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║              🎉 Installation Complete! 🎉                  ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "⏱️  Installation time: ${MINUTES}m ${SECONDS}s"
echo ""
echo "🌐 Services:"
echo "   • OmniRoute Dashboard: http://localhost:20128"
echo "   • OpenClaw Gateway:    http://localhost:18789"
echo "   • Memory Dashboard:    http://localhost:20128/dashboard/memory"
echo ""
echo "🔐 Default credentials:"
echo "   • OmniRoute: admin / admin"
echo "   • OpenClaw:  Check .env file for OPENCLAW_PASSWORD"
echo ""
echo "⚠️  IMPORTANT: Change default passwords after first login!"
echo ""
echo "📂 Installation directory: $PROJECT_ROOT"
echo ""
echo "🛠  Useful commands:"
echo "   cd $PROJECT_ROOT"
echo "   docker compose logs -f          # View logs"
echo "   docker compose restart          # Restart services"
echo "   docker compose down             # Stop services"
echo "   ./scripts/enable-memory.sh      # Re-enable Memory Management"
echo ""
echo "📚 Documentation:"
echo "   • QUICK_DEPLOY.md - Quick deployment guide"
echo "   • INTEGRATION_COMPLETE.md - OpenCode Memory integration"
echo "   • README.md - Full documentation"
echo ""
echo "💡 OpenCode Integration:"
echo "   1. Restart OpenCode to load MCP server"
echo "   2. Test: 'Какие MCP инструменты доступны?'"
echo "   3. Use: 'Запомни, что этот проект называется OmniRoute'"
echo ""
print_success "All systems operational!"
echo ""
