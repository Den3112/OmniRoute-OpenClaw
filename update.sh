#!/bin/bash
# OmniRoute-OpenClaw One-Click Installer & Updater
set -e

export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Colors for output
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Helper functions
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_info() { echo -e "${BLUE}ℹ${NC} $1"; }
print_step() { echo ""; echo -e "${BLUE}==>${NC} $1"; }

# Start timer
START_TIME=$(date +%s)

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        print_error "Script failed with exit code $exit_code"
        echo "📋 Cleaning up..."
        $DOCKER_COMPOSE down --remove-orphans 2>/dev/null || true
    fi
    exit $exit_code
}

trap cleanup EXIT

echo "🚀 Starting OmniRoute-OpenClaw Setup..."
echo ""

# ============================================================================
# 0. PRE-FLIGHT CHECKS
# ============================================================================

print_step "Checking system requirements..."

# Check Docker
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is required but not installed"
    echo "   Install: https://docs.docker.com/get-docker/"
    exit 1
fi
print_success "Docker found"

# Check Git
if ! command -v git >/dev/null 2>&1; then
    print_error "Git is required but not installed"
    echo "   Install: https://git-scm.com/downloads"
    exit 1
fi
print_success "Git found"

# Detect Docker Compose command (v1 vs v2)
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
    COMPOSE_VERSION=$(docker compose version --short 2>/dev/null)
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
    COMPOSE_VERSION=$(docker-compose version --short 2>/dev/null)
else
    print_error "Docker Compose not found"
    echo "   Install: https://docs.docker.com/compose/install/"
    exit 1
fi
print_success "Docker Compose: $COMPOSE_VERSION"

# Warn if v1.x
MAJOR_VERSION=$(echo "$COMPOSE_VERSION" | cut -d. -f1)
if [ "$MAJOR_VERSION" -lt 2 ]; then
    print_warning "Docker Compose v1.x detected"
    echo "   Some features may not work. Upgrade to v2.x recommended."
    read -p "   Continue anyway? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        exit 1
    fi
fi

# Detect platform
PLATFORM=$(uname -s)
case "$PLATFORM" in
    Linux*)
        OS="Linux"
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS="WSL"
            print_info "Windows Subsystem for Linux detected"
        fi
        ;;
    Darwin*)
        OS="macOS"
        print_info "macOS detected"
        ;;
    MINGW*|MSYS*|CYGWIN*)
        print_error "Native Windows is not supported"
        echo "   Please use WSL2: https://docs.microsoft.com/en-us/windows/wsl/install"
        exit 1
        ;;
    *)
        print_warning "Unknown platform: $PLATFORM"
        echo "   Proceeding with Linux defaults..."
        OS="Linux"
        ;;
esac

# Check if we need sudo
SUDO=""
if [ "$(id -u)" -ne 0 ] && [ "$OS" = "Linux" ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
        print_info "Some operations will require sudo privileges"
    else
        print_warning "Running without root/sudo - permission errors may occur"
    fi
fi

# Check available disk space
print_step "Checking disk space..."
if command -v df >/dev/null 2>&1; then
    if [ "$OS" = "macOS" ]; then
        AVAILABLE_GB=$(df -g . 2>/dev/null | tail -1 | awk '{print $4}' || echo "0")
    else
        AVAILABLE_GB=$(df -BG . 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/G//' || echo "0")
    fi
    
    REQUIRED_GB=10
    if [ "$AVAILABLE_GB" -lt "$REQUIRED_GB" ]; then
        print_warning "Low disk space: ${AVAILABLE_GB}GB available"
        echo "   Required: ${REQUIRED_GB}GB"
        echo "   Docker images and data will require significant space."
        read -p "   Continue anyway? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 1
        fi
    else
        print_success "Disk space: ${AVAILABLE_GB}GB available"
    fi
fi

# Check if ports are available
print_step "Checking ports..."

check_port() {
    local port=$1
    if command -v lsof >/dev/null 2>&1; then
        lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 && return 1
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tuln 2>/dev/null | grep -q ":$port " && return 1
    elif command -v ss >/dev/null 2>&1; then
        ss -tuln 2>/dev/null | grep -q ":$port " && return 1
    fi
    return 0
}

PORT_WARNINGS=0
if ! check_port 20128; then
    print_warning "Port 20128 is already in use (OmniRoute)"
    echo "   You can change it in .env (PORT=20128)"
    PORT_WARNINGS=$((PORT_WARNINGS + 1))
else
    print_success "Port 20128 available (OmniRoute)"
fi

if ! check_port 18789; then
    print_warning "Port 18789 is already in use (OpenClaw)"
    echo "   You can change it in docker-compose.yml"
    PORT_WARNINGS=$((PORT_WARNINGS + 1))
else
    print_success "Port 18789 available (OpenClaw)"
fi

if [ $PORT_WARNINGS -gt 0 ]; then
    echo ""
    read -p "   Continue with port conflicts? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled."
        echo "Please stop services using these ports or change ports in configuration."
        exit 1
    fi
fi

# ============================================================================
# 1. DATA MIGRATION
# ============================================================================

print_step "Checking for existing data..."

OLD_OMNI="$HOME/.omniroute"
OLD_OPENCLAW="$HOME/.openclaw"
NEW_DATA_DIR="./data"

if [ ! -d "$NEW_DATA_DIR" ]; then
    mkdir -p "$NEW_DATA_DIR"
    if [ -d "$OLD_OMNI" ]; then
        print_info "Migrating OmniRoute data from $OLD_OMNI..."
        cp -r "$OLD_OMNI" "$NEW_DATA_DIR/omniroute"
    fi
    if [ -d "$OLD_OPENCLAW" ]; then
        print_info "Migrating OpenClaw data from $OLD_OPENCLAW..."
        cp -r "$OLD_OPENCLAW" "$NEW_DATA_DIR/openclaw"
    fi
fi

# Platform-specific permissions
print_step "Setting permissions..."
mkdir -p "$NEW_DATA_DIR/openclaw" "$NEW_DATA_DIR/omniroute"

if [ "$OS" = "macOS" ] || [ "$OS" = "WSL" ]; then
    # macOS/WSL: use current user (Docker Desktop handles mapping)
    $SUDO chown -R "$(id -u):$(id -g)" "$NEW_DATA_DIR/openclaw" 2>/dev/null || true
    print_info "Using current user permissions ($OS)"
else
    # Linux: use UID 1000 (standard Docker user)
    $SUDO chown -R 1000:1000 "$NEW_DATA_DIR/openclaw" 2>/dev/null || true
fi

$SUDO chmod -R 755 "$NEW_DATA_DIR/openclaw"
print_success "Permissions configured"

# ============================================================================
# 2. SUBMODULE INITIALIZATION
# ============================================================================

print_step "Checking submodules..."

if [ ! -f "OmniRoute/package.json" ] || [ ! -f "openclaw/package.json" ]; then
    print_info "Initializing submodules (this may take a few minutes)..."
    
    if ! git submodule update --init --recursive; then
        echo ""
        print_error "Failed to initialize submodules"
        echo ""
        echo "This might be due to:"
        echo "  • Network connectivity issues"
        echo "  • Git authentication problems"
        echo "  • Corrupted .git directory"
        echo ""
        echo "Try manually:"
        echo "  git submodule update --init --recursive"
        exit 1
    fi
    
    # Verify submodules are present
    if [ ! -f "OmniRoute/package.json" ]; then
        print_error "OmniRoute submodule not properly initialized"
        echo "   Missing: OmniRoute/package.json"
        exit 1
    fi
    
    if [ ! -f "openclaw/package.json" ]; then
        print_error "OpenClaw submodule not properly initialized"
        echo "   Missing: openclaw/package.json"
        exit 1
    fi
    
    print_success "Submodules initialized"
else
    print_success "Submodules already present"
    print_info "Updating submodules to latest versions..."
    
    if ! git submodule update --remote --merge; then
        print_warning "Failed to update submodules"
        echo "   Continuing with current versions..."
    else
        print_success "Submodules updated"
    fi
fi

# ============================================================================
# 3. ENVIRONMENT & SECRET GENERATION
# ============================================================================

print_step "Configuring environment..."

if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        print_info "Creating .env from example..."
        cp .env.example .env
    else
        touch .env
    fi
fi

# Function to generate random hex (with multiple fallbacks)
generate_random_hex() {
    # Try openssl first (most reliable)
    if command -v openssl >/dev/null 2>&1; then
        openssl rand -hex 32 2>/dev/null && return 0
    fi
    
    # Try xxd (common on Linux/macOS)
    if command -v xxd >/dev/null 2>&1; then
        xxd -p -l 32 /dev/urandom 2>/dev/null | tr -d '\n' && return 0
    fi
    
    # Try od (POSIX-compliant, works everywhere)
    if command -v od >/dev/null 2>&1; then
        od -An -tx1 -N32 /dev/urandom 2>/dev/null | tr -d ' \n' && return 0
    fi
    
    # Last resort: hexdump
    if command -v hexdump >/dev/null 2>&1; then
        hexdump -n 32 -e '32/1 "%02x" "\n"' /dev/urandom 2>/dev/null && return 0
    fi
    
    echo "ERROR: No suitable random generator found" >&2
    return 1
}

# Function to generate secret if empty or missing
generate_secret() {
    local var_name=$1
    local current_val=$(grep "^${var_name}=" .env 2>/dev/null | cut -d'=' -f2 || true)
    
    if [ -z "$current_val" ] || [ "$current_val" == "CHANGEME" ] || [[ "$current_val" == *"replace_this"* ]]; then
        print_info "Generating secure $var_name..."
        
        local new_val=$(generate_random_hex)
        if [ -z "$new_val" ]; then
            print_error "Failed to generate secure random value for $var_name"
            echo "   Please install openssl, xxd, od, or hexdump"
            exit 1
        fi
        
        if grep -q "^${var_name}=" .env 2>/dev/null; then
            sed "s|^${var_name}=.*|${var_name}=${new_val}|" .env > .env.tmp && mv .env.tmp .env
        else
            echo "${var_name}=${new_val}" >> .env
        fi
    fi
}

generate_secret "STORAGE_ENCRYPTION_KEY"
generate_secret "JWT_SECRET"
generate_secret "API_KEY_SECRET"
generate_secret "OPENCLAW_PASSWORD"

# Ensure encryption key version is set
if ! grep -q "^STORAGE_ENCRYPTION_KEY_VERSION=" .env 2>/dev/null; then
    echo "STORAGE_ENCRYPTION_KEY_VERSION=v1" >> .env
fi

print_success "Environment configured"

# ============================================================================
# 4. DOCKER BUILD AND RUN
# ============================================================================

print_step "Building and starting containers..."
print_info "This may take 10-20 minutes on first run..."

# Try to pull pre-built images first (if available)
if $DOCKER_COMPOSE pull 2>/dev/null; then
    print_success "Using pre-built images"
else
    print_info "Pre-built images not available, building locally..."
fi

$DOCKER_COMPOSE build --parallel --pull --progress=plain
$DOCKER_COMPOSE up -d

print_success "Containers started"

# ============================================================================
# 5. HEALTH CHECK
# ============================================================================

print_step "Waiting for services to become healthy..."

MAX_RETRIES=30
COUNT=0
while [ $COUNT -lt $MAX_RETRIES ]; do
    UNHEALTHY=$(docker ps --filter "health=unhealthy" --filter "name=omniroute" --filter "name=openclaw" -q 2>/dev/null)
    STARTING=$(docker ps --filter "health=starting" --filter "name=omniroute" --filter "name=openclaw" -q 2>/dev/null)
    
    if [ -z "$UNHEALTHY" ] && [ -z "$STARTING" ]; then
        print_success "All services are healthy!"
        break
    fi
    
    echo "   Waiting for services... ($((COUNT+1))/$MAX_RETRIES)"
    sleep 10
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    print_warning "Some services are still not healthy"
    echo "   Check status: docker ps"
    echo "   Check logs: docker logs omniroute"
    echo "   Check logs: docker logs openclaw"
fi

# ============================================================================
# 6. CLEANUP
# ============================================================================

print_step "Cleaning up..."
docker image prune -f >/dev/null 2>&1
print_success "Cleanup complete"

# ============================================================================
# DONE
# ============================================================================

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
MINUTES=$((ELAPSED / 60))
SECONDS=$((ELAPSED % 60))

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_success "Installation completed in ${MINUTES}m ${SECONDS}s"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📍 OmniRoute Dashboard: http://localhost:20128"
echo "   Default login: admin / admin"
echo "   ⚠️  Change password after first login!"
echo ""
echo "📍 OpenClaw Gateway: http://localhost:18789"
echo "   Token: Check OPENCLAW_PASSWORD in .env"
echo ""
echo "📊 Monitor status: ./monitor.sh"
echo "🔄 Quick restart: ./restart.sh"
echo "📋 View logs: ./logs.sh"
echo ""
print_success "ALL SYSTEMS GO!"
