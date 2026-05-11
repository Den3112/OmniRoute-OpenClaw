#!/usr/bin/env bash
#
# test-install.sh - Local installation testing script
#
# This script tests the installation process locally before pushing to CI/CD.
# It simulates the CI/CD environment and runs the same checks.
#
# Usage:
#   ./test-install.sh [--clean|--keep|--verbose]
#
# Options:
#   --clean     Clean up Docker resources before testing (default)
#   --keep      Keep containers running after test
#   --verbose   Show detailed output
#   --help      Show this help message
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CLEAN_BEFORE=true
KEEP_AFTER=false
VERBOSE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_step() {
    echo ""
    echo -e "${BLUE}==>${NC} $1"
    echo ""
}

show_help() {
    head -n 15 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            CLEAN_BEFORE=true
            shift
            ;;
        --keep)
            KEEP_AFTER=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            ;;
    esac
done

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test function
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    echo -n "Testing: $test_name... "
    
    if [ "$VERBOSE" = true ]; then
        echo ""
        if eval "$test_command"; then
            log_success "$test_name"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            log_error "$test_name"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    else
        if eval "$test_command" >/dev/null 2>&1; then
            log_success "PASS"
            TESTS_PASSED=$((TESTS_PASSED + 1))
            return 0
        else
            log_error "FAIL"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            return 1
        fi
    fi
}

# Cleanup function
cleanup() {
    if [ "$KEEP_AFTER" = false ]; then
        log_step "Cleaning up..."
        docker compose down -v >/dev/null 2>&1 || true
        log_success "Cleanup complete"
    else
        log_info "Keeping containers running (--keep flag)"
    fi
}

trap cleanup EXIT

# Main test suite
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         OmniRoute + OpenClaw Installation Test            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    START_TIME=$(date +%s)
    
    # Pre-flight checks
    log_step "Pre-flight checks"
    
    run_test "Docker installed" "command -v docker"
    run_test "Docker Compose installed" "docker compose version"
    run_test "Git installed" "command -v git"
    run_test "Curl installed" "command -v curl"
    run_test "JQ installed" "command -v jq"
    
    # System info
    log_step "System information"
    
    echo "OS: $(uname -s)"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    
    if command -v nproc >/dev/null 2>&1; then
        echo "CPU cores: $(nproc)"
    fi
    
    if command -v free >/dev/null 2>&1; then
        echo "Memory: $(free -h | grep Mem | awk '{print $2}')"
    fi
    
    echo "Disk space: $(df -h . | tail -1 | awk '{print $4}') available"
    
    # Clean up before test
    if [ "$CLEAN_BEFORE" = true ]; then
        log_step "Cleaning up existing installation"
        docker compose down -v >/dev/null 2>&1 || true
        rm -f .env
        log_success "Cleanup complete"
    fi
    
    # Test installation
    log_step "Testing installation script"
    
    if [ "$VERBOSE" = true ]; then
        ./update.sh --yes
    else
        ./update.sh --yes >/dev/null 2>&1
    fi
    
    log_success "Installation script completed"
    
    # Test .env file
    log_step "Testing .env file generation"
    
    run_test ".env file exists" "[ -f .env ]"
    run_test "STORAGE_ENCRYPTION_KEY set" "grep -q '^STORAGE_ENCRYPTION_KEY=.' .env"
    run_test "JWT_SECRET set" "grep -q '^JWT_SECRET=.' .env"
    run_test "API_KEY_SECRET set" "grep -q '^API_KEY_SECRET=.' .env"
    run_test "OPENCLAW_PASSWORD set" "grep -q '^OPENCLAW_PASSWORD=.' .env"
    run_test "INITIAL_PASSWORD set" "grep -q '^INITIAL_PASSWORD=.' .env"
    
    # Check for default passwords
    log_step "Checking for secure passwords"
    
    OPENCLAW_PASS=$(grep "^OPENCLAW_PASSWORD=" .env | cut -d= -f2)
    INITIAL_PASS=$(grep "^INITIAL_PASSWORD=" .env | cut -d= -f2)
    
    if [ "$OPENCLAW_PASS" == "admin" ]; then
        log_warning "OPENCLAW_PASSWORD is still 'admin' (should be random)"
    else
        log_success "OPENCLAW_PASSWORD is randomized"
    fi
    
    if [ "$INITIAL_PASS" == "admin" ]; then
        log_warning "INITIAL_PASSWORD is still 'admin' (should be random)"
    else
        log_success "INITIAL_PASSWORD is randomized"
    fi
    
    # Wait for services
    log_step "Waiting for services to start"
    
    MAX_RETRIES=60
    COUNT=0
    
    while [ $COUNT -lt $MAX_RETRIES ]; do
        UNHEALTHY=$(docker ps --filter "health=unhealthy" --filter "name=omniroute" --filter "name=openclaw" -q 2>/dev/null || true)
        STARTING=$(docker ps --filter "health=starting" --filter "name=omniroute" --filter "name=openclaw" -q 2>/dev/null || true)
        
        if [ -z "$UNHEALTHY" ] && [ -z "$STARTING" ]; then
            log_success "All services are healthy"
            break
        fi
        
        if [ "$VERBOSE" = true ]; then
            echo "Waiting for services... ($((COUNT+1))/$MAX_RETRIES)"
        fi
        
        sleep 5
        COUNT=$((COUNT+1))
    done
    
    if [ $COUNT -eq $MAX_RETRIES ]; then
        log_error "Services did not become healthy in time"
        docker ps
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    # Test containers
    log_step "Testing container status"
    
    run_test "OmniRoute container running" "docker ps | grep -q omniroute"
    run_test "OpenClaw container running" "docker ps | grep -q openclaw"
    run_test "Redis container running" "docker ps | grep -q omniroute-redis"
    
    # Test health endpoints
    log_step "Testing health endpoints"
    
    # Wait for OmniRoute
    COUNT=0
    while [ $COUNT -lt 30 ]; do
        if curl -f -s http://localhost:20128/api/monitoring/health >/dev/null 2>&1; then
            break
        fi
        sleep 2
        COUNT=$((COUNT+1))
    done
    
    run_test "OmniRoute health endpoint" "curl -f -s http://localhost:20128/api/monitoring/health"
    
    # Wait for OpenClaw
    COUNT=0
    while [ $COUNT -lt 30 ]; do
        if curl -f -s http://localhost:18789/healthz >/dev/null 2>&1; then
            break
        fi
        sleep 2
        COUNT=$((COUNT+1))
    done
    
    run_test "OpenClaw health endpoint" "curl -f -s http://localhost:18789/healthz"
    
    # Test Redis
    run_test "Redis connection" "docker exec omniroute-redis redis-cli ping | grep -q PONG"
    
    # Test management scripts
    log_step "Testing management scripts"
    
    run_test "status.sh executable" "[ -x status.sh ]"
    run_test "monitor.sh executable" "[ -x monitor.sh ]"
    run_test "healthcheck.sh executable" "[ -x healthcheck.sh ]"
    run_test "backup.sh executable" "[ -x backup.sh ]"
    run_test "restart.sh executable" "[ -x restart.sh ]"
    run_test "rotate-secrets.sh executable" "[ -x rotate-secrets.sh ]"
    
    # Run healthcheck
    if [ "$VERBOSE" = true ]; then
        ./healthcheck.sh
    else
        run_test "healthcheck.sh runs" "./healthcheck.sh >/dev/null 2>&1"
    fi
    
    # Test backup
    log_step "Testing backup functionality"
    
    if [ "$VERBOSE" = true ]; then
        ./backup.sh
    else
        ./backup.sh >/dev/null 2>&1
    fi
    
    run_test "Backup directory created" "[ -d backups ]"
    run_test "Backup file created" "[ -n \"\$(ls -A backups/*.tar.gz 2>/dev/null)\" ]"
    
    # Resource usage
    log_step "Resource usage"
    
    echo ""
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo ""
    
    # Documentation check
    log_step "Testing documentation"
    
    run_test "README.md exists" "[ -f README.md ]"
    run_test "INSTALL.md exists" "[ -f INSTALL.md ]"
    run_test "TROUBLESHOOTING.md exists" "[ -f TROUBLESHOOTING.md ]"
    run_test "ARCHITECTURE.md exists" "[ -f ARCHITECTURE.md ]"
    run_test "Russian INSTALL.md exists" "[ -f docs/ru/INSTALL.md ]"
    
    # Calculate results
    END_TIME=$(date +%s)
    ELAPSED=$((END_TIME - START_TIME))
    MINUTES=$((ELAPSED / 60))
    SECONDS=$((ELAPSED % 60))
    
    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "                        TEST SUMMARY                           "
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Total tests: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo "Time elapsed: ${MINUTES}m ${SECONDS}s"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "✓ ALL TESTS PASSED!"
        echo ""
        echo "Your installation is working correctly."
        echo ""
        echo "Access your services:"
        echo "  OmniRoute: http://localhost:20128"
        echo "  OpenClaw:  http://localhost:18789"
        echo ""
        return 0
    else
        log_error "✗ SOME TESTS FAILED"
        echo ""
        echo "Please check the errors above and:"
        echo "  1. Review logs: ./logs.sh"
        echo "  2. Check status: ./status.sh"
        echo "  3. See troubleshooting: TROUBLESHOOTING.md"
        echo ""
        return 1
    fi
}

# Run main function
main
