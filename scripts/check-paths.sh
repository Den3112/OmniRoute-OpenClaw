#!/bin/bash
# check-paths.sh - Validate project structure and paths
# Ensures all paths are relative and project is portable

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

# Detect project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Project Structure Validation                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
print_info "Project root: $PROJECT_ROOT"
echo ""

ERRORS=0
WARNINGS=0

# Check required files
echo "--- Checking Required Files ---"
REQUIRED_FILES=(
    "docker-compose.yml"
    ".env"
    ".env.example"
    ".gitignore"
    "README.md"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$PROJECT_ROOT/$file" ]; then
        print_success "$file exists"
    else
        print_error "$file is missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check required directories
echo "--- Checking Required Directories ---"
REQUIRED_DIRS=(
    "data"
    "openclaw"
    "OmniRoute"
    "scripts"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$PROJECT_ROOT/$dir" ]; then
        print_success "$dir/ exists"
    else
        print_error "$dir/ is missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check data subdirectories
echo "--- Checking Data Structure ---"
if [ -d "$PROJECT_ROOT/data" ]; then
    if [ -d "$PROJECT_ROOT/data/openclaw" ]; then
        print_success "data/openclaw/ exists"
    else
        print_warning "data/openclaw/ will be created on first run"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if [ -d "$PROJECT_ROOT/data/omniroute" ]; then
        print_success "data/omniroute/ exists"
    else
        print_warning "data/omniroute/ will be created on first run"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_error "data/ directory is missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check .env configuration
echo "--- Checking .env Configuration ---"
if [ -f "$PROJECT_ROOT/.env" ]; then
    if grep -q "PROJECT_ROOT=" "$PROJECT_ROOT/.env"; then
        print_success "PROJECT_ROOT is defined in .env"
    else
        print_warning "PROJECT_ROOT not found in .env (optional)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "OPENCLAW_DATA_DIR=" "$PROJECT_ROOT/.env"; then
        print_success "OPENCLAW_DATA_DIR is defined in .env"
    else
        print_warning "OPENCLAW_DATA_DIR not found in .env (will use default)"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "OMNIROUTE_DATA_DIR=" "$PROJECT_ROOT/.env"; then
        print_success "OMNIROUTE_DATA_DIR is defined in .env"
    else
        print_warning "OMNIROUTE_DATA_DIR not found in .env (will use default)"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_error ".env file is missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check docker-compose.yml for relative paths
echo "--- Checking docker-compose.yml ---"
if [ -f "$PROJECT_ROOT/docker-compose.yml" ]; then
    if grep -q '\${OPENCLAW_DATA_DIR:-./data/openclaw}' "$PROJECT_ROOT/docker-compose.yml"; then
        print_success "OpenClaw volume uses variable path"
    else
        print_warning "OpenClaw volume may use hardcoded path"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q '\${OMNIROUTE_DATA_DIR:-./data/omniroute}' "$PROJECT_ROOT/docker-compose.yml"; then
        print_success "OmniRoute volume uses variable path"
    else
        print_warning "OmniRoute volume may use hardcoded path"
        WARNINGS=$((WARNINGS + 1))
    fi
else
    print_error "docker-compose.yml is missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Check for absolute paths in scripts (potential issues)
echo "--- Checking Scripts for Hardcoded Paths ---"
SCRIPTS_TO_CHECK=(
    "bootstrap.sh"
    "install.sh"
    "restart.sh"
    "monitor.sh"
    "start-monitoring.sh"
)

for script in "${SCRIPTS_TO_CHECK[@]}"; do
    if [ -f "$PROJECT_ROOT/$script" ]; then
        # Check for /home/node hardcoded paths (should only be in container context)
        if grep -q "/home/node" "$PROJECT_ROOT/$script" 2>/dev/null; then
            print_warning "$script contains /home/node path (verify it's container-only)"
            WARNINGS=$((WARNINGS + 1))
        else
            print_success "$script looks good"
        fi
    fi
done
echo ""

# Check Docker containers
echo "--- Checking Docker Containers ---"
if command -v docker >/dev/null 2>&1; then
    if docker ps -a --filter "name=openclaw" --format "{{.Names}}" | grep -q openclaw; then
        OPENCLAW_MOUNTS=$(docker inspect openclaw --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null || echo "")
        if echo "$OPENCLAW_MOUNTS" | grep -q "$PROJECT_ROOT/data/openclaw"; then
            print_success "OpenClaw container uses project-relative data path"
        else
            print_warning "OpenClaw container mount may not be project-relative"
            echo "   Current mounts:"
            echo "$OPENCLAW_MOUNTS" | sed 's/^/   /'
            WARNINGS=$((WARNINGS + 1))
        fi
    else
        print_info "OpenClaw container not running (start with: docker compose up -d)"
    fi
else
    print_warning "Docker not available, skipping container checks"
    WARNINGS=$((WARNINGS + 1))
fi
echo ""

# Summary
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                    Validation Summary                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "All checks passed! Project structure is valid."
    echo ""
    print_info "Project is portable and ready for:"
    echo "   • Git clone to any directory"
    echo "   • Docker image creation"
    echo "   • Deployment to different environments"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    print_warning "Validation completed with $WARNINGS warning(s)"
    echo ""
    print_info "Project structure is mostly correct, but review warnings above"
    echo ""
    exit 0
else
    print_error "Validation failed with $ERRORS error(s) and $WARNINGS warning(s)"
    echo ""
    print_info "Fix errors above before deploying"
    echo ""
    exit 1
fi
