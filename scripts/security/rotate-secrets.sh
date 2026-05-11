#!/usr/bin/env bash
#
# rotate-secrets.sh - Rotate security secrets for OmniRoute + OpenClaw
#
# This script safely rotates all security-sensitive secrets:
# - STORAGE_ENCRYPTION_KEY
# - JWT_SECRET
# - API_KEY_SECRET
# - OPENCLAW_PASSWORD
# - INITIAL_PASSWORD
#
# Usage:
#   ./rotate-secrets.sh [--all|--passwords|--keys]
#
# Options:
#   --all         Rotate all secrets (default)
#   --passwords   Rotate only passwords (OPENCLAW_PASSWORD, INITIAL_PASSWORD)
#   --keys        Rotate only encryption keys (STORAGE_ENCRYPTION_KEY, JWT_SECRET, API_KEY_SECRET)
#   --backup      Create backup before rotation
#   --no-restart  Don't restart services after rotation
#   --help        Show this help message
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
ENV_FILE=".env"
BACKUP_DIR="backups"
ROTATE_ALL=true
ROTATE_PASSWORDS=false
ROTATE_KEYS=false
CREATE_BACKUP=true
RESTART_SERVICES=true

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    head -n 20 "$0" | grep "^#" | sed 's/^# \?//'
    exit 0
}

# Generate secure random value (64 characters)
generate_secret() {
    local length="${1:-64}"
    
    # Try multiple methods in order of preference
    if command -v openssl &> /dev/null; then
        openssl rand -hex "$((length / 2))"
    elif command -v xxd &> /dev/null && [ -r /dev/urandom ]; then
        head -c "$((length / 2))" /dev/urandom | xxd -p -c "$((length / 2))"
    elif command -v od &> /dev/null && [ -r /dev/urandom ]; then
        od -An -tx1 -N "$((length / 2))" /dev/urandom | tr -d ' \n'
    elif command -v hexdump &> /dev/null && [ -r /dev/urandom ]; then
        hexdump -n "$((length / 2))" -e '"%02x"' /dev/urandom
    else
        log_error "No suitable random generator found. Install openssl, xxd, od, or hexdump."
        exit 1
    fi
}

# Generate secure password (32 characters, alphanumeric + special chars)
generate_password() {
    local length="${1:-32}"
    
    if command -v openssl &> /dev/null; then
        # Generate base64 and clean it up
        openssl rand -base64 "$((length * 3 / 4))" | tr -d '\n' | head -c "$length"
    else
        # Fallback to hex
        generate_secret "$length"
    fi
}

# Backup current .env file
backup_env() {
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found!"
        exit 1
    fi
    
    mkdir -p "$BACKUP_DIR"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/.env.backup.$timestamp"
    
    cp "$ENV_FILE" "$backup_file"
    log_success "Backed up .env to $backup_file"
    
    # Keep only last 10 backups
    ls -t "$BACKUP_DIR"/.env.backup.* 2>/dev/null | tail -n +11 | xargs -r rm
}

# Update secret in .env file
update_secret() {
    local key="$1"
    local value="$2"
    
    if grep -q "^${key}=" "$ENV_FILE"; then
        # Update existing key
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
        else
            # Linux
            sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
        fi
        log_success "Updated $key"
    else
        # Add new key
        echo "${key}=${value}" >> "$ENV_FILE"
        log_success "Added $key"
    fi
}

# Rotate encryption keys
rotate_encryption_keys() {
    log_info "Rotating encryption keys..."
    
    local storage_key=$(generate_secret 64)
    local jwt_secret=$(generate_secret 64)
    local api_key_secret=$(generate_secret 64)
    
    update_secret "STORAGE_ENCRYPTION_KEY" "$storage_key"
    update_secret "JWT_SECRET" "$jwt_secret"
    update_secret "API_KEY_SECRET" "$api_key_secret"
    
    log_warning "⚠️  IMPORTANT: Rotating encryption keys will invalidate:"
    log_warning "   - All existing encrypted data"
    log_warning "   - All existing JWT tokens"
    log_warning "   - All existing API keys"
    log_warning "   You will need to re-add provider API keys and re-login to dashboard."
}

# Rotate passwords
rotate_passwords() {
    log_info "Rotating passwords..."
    
    local openclaw_password=$(generate_password 32)
    local initial_password=$(generate_password 16)
    
    update_secret "OPENCLAW_PASSWORD" "$openclaw_password"
    update_secret "INITIAL_PASSWORD" "$initial_password"
    
    log_success "New OpenClaw password: $openclaw_password"
    log_success "New OmniRoute admin password: $initial_password"
    
    log_warning "⚠️  Save these passwords securely!"
}

# Check if services are running
check_services() {
    if docker compose ps | grep -q "Up"; then
        return 0
    else
        return 1
    fi
}

# Restart services
restart_services() {
    log_info "Restarting services..."
    
    if check_services; then
        ./restart.sh
        log_success "Services restarted"
    else
        log_warning "Services are not running. Start them with: docker compose up -d"
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                ROTATE_ALL=true
                ROTATE_PASSWORDS=false
                ROTATE_KEYS=false
                shift
                ;;
            --passwords)
                ROTATE_ALL=false
                ROTATE_PASSWORDS=true
                shift
                ;;
            --keys)
                ROTATE_ALL=false
                ROTATE_KEYS=true
                shift
                ;;
            --backup)
                CREATE_BACKUP=true
                shift
                ;;
            --no-restart)
                RESTART_SERVICES=false
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
}

# Main function
main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         OmniRoute + OpenClaw Secret Rotation Tool         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    parse_args "$@"
    
    # Check if .env exists
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found! Run ./update.sh first."
        exit 1
    fi
    
    # Create backup
    if [ "$CREATE_BACKUP" = true ]; then
        backup_env
    fi
    
    # Confirm action
    echo ""
    log_warning "This will rotate the following secrets:"
    if [ "$ROTATE_ALL" = true ] || [ "$ROTATE_KEYS" = true ]; then
        echo "  - STORAGE_ENCRYPTION_KEY"
        echo "  - JWT_SECRET"
        echo "  - API_KEY_SECRET"
    fi
    if [ "$ROTATE_ALL" = true ] || [ "$ROTATE_PASSWORDS" = true ]; then
        echo "  - OPENCLAW_PASSWORD"
        echo "  - INITIAL_PASSWORD"
    fi
    echo ""
    
    read -p "Are you sure you want to continue? (yes/no): " -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        log_info "Aborted."
        exit 0
    fi
    
    # Rotate secrets
    if [ "$ROTATE_ALL" = true ]; then
        rotate_encryption_keys
        rotate_passwords
    else
        if [ "$ROTATE_KEYS" = true ]; then
            rotate_encryption_keys
        fi
        if [ "$ROTATE_PASSWORDS" = true ]; then
            rotate_passwords
        fi
    fi
    
    echo ""
    log_success "✓ All secrets rotated successfully!"
    echo ""
    
    # Show new credentials
    log_info "New credentials:"
    echo ""
    echo "  OmniRoute Dashboard:"
    echo "    URL: http://localhost:$(grep "^PORT=" "$ENV_FILE" | cut -d= -f2)"
    echo "    Username: admin"
    echo "    Password: $(grep "^INITIAL_PASSWORD=" "$ENV_FILE" | cut -d= -f2)"
    echo ""
    echo "  OpenClaw Gateway:"
    echo "    URL: http://localhost:$(grep "^OPENCLAW_PORT=" "$ENV_FILE" | cut -d= -f2)"
    echo "    Token: $(grep "^OPENCLAW_PASSWORD=" "$ENV_FILE" | cut -d= -f2)"
    echo ""
    
    # Restart services
    if [ "$RESTART_SERVICES" = true ]; then
        echo ""
        restart_services
    else
        log_warning "Services not restarted. Restart manually with: ./restart.sh"
    fi
    
    echo ""
    log_success "✓ Secret rotation complete!"
    echo ""
    log_warning "⚠️  IMPORTANT NEXT STEPS:"
    echo "  1. Save the new credentials securely"
    echo "  2. Re-add your AI provider API keys in OmniRoute dashboard"
    echo "  3. Update any applications using the old credentials"
    echo "  4. Test all services: ./healthcheck.sh"
    echo ""
}

# Run main function
main "$@"
