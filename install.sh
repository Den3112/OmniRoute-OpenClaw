#!/bin/bash
# OmniRoute-OpenClaw One-Command Installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Den3112/OmniRoute-OpenClaw/main/install.sh | bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_step() { echo ""; echo -e "${BLUE}==>${NC} $1"; }

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║     OmniRoute + OpenClaw One-Command Installer            ║"
echo "║     Automatic Setup - No Questions Asked                  ║"
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

# Detect project root (if running from existing installation)
if [ -f "$(dirname "$0")/docker-compose.yml" ]; then
    PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
    print_info "Running from existing installation: $PROJECT_ROOT"
else
    PROJECT_ROOT="$INSTALL_DIR"
    print_step "Installation directory: $PROJECT_ROOT"
fi

# Check prerequisites
print_step "Checking prerequisites..."

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

if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed"
    echo ""
    echo "Install Docker first:"
    echo "  https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker found"

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

# Clone repository
print_step "Cloning repository..."

if [ -d "$INSTALL_DIR" ]; then
    print_info "Directory exists, updating..."
    cd "$INSTALL_DIR"
    PROJECT_ROOT="$(pwd)"
    git pull --rebase 2>/dev/null || true
    git submodule update --init --recursive
else
    git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    PROJECT_ROOT="$(pwd)"
fi

print_success "Repository ready at $PROJECT_ROOT"

# Make scripts executable
chmod +x update.sh restart.sh 2>/dev/null || true

# Run automatic installation
print_step "Starting automatic installation..."
echo ""

./update.sh --yes

# Final message
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║                  🎉 Installation Complete! 🎉              ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📍 Services:"
echo "   • OmniRoute Dashboard: http://localhost:20128"
echo "   • OpenClaw Gateway:    http://localhost:18789"
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
echo "   ./restart.sh      # Restart services"
echo "   ./monitor.sh      # Monitor status"
echo "   docker compose logs -f  # View logs"
echo ""
print_success "All systems operational!"
