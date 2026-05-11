#!/bin/bash
# generate-secrets.sh - Auto-generate secure secrets for .env file
# Usage: ./scripts/generate-secrets.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

echo "🔐 Generating secure secrets..."

# Check if .env exists
if [ -f .env ]; then
    print_info ".env file already exists"
    read -p "   Overwrite existing secrets? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "   Keeping existing .env file"
        exit 0
    fi
    # Backup existing .env
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    print_info "Backed up existing .env"
fi

# Copy from example if .env doesn't exist
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        print_success "Created .env from .env.example"
    else
        echo "ERROR: .env.example not found"
        exit 1
    fi
fi

# Generate cryptographically secure secrets
STORAGE_KEY=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 32)
API_SECRET=$(openssl rand -hex 32)
OPENCLAW_PASS=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
OMNIROUTE_KEY="sk-$(openssl rand -hex 16 | cut -c1-16)-$(openssl rand -hex 3)-$(openssl rand -hex 4)"

# Update .env file
sed -i "s|STORAGE_ENCRYPTION_KEY=.*|STORAGE_ENCRYPTION_KEY=$STORAGE_KEY|" .env
sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
sed -i "s|API_KEY_SECRET=.*|API_KEY_SECRET=$API_SECRET|" .env
sed -i "s|OPENCLAW_PASSWORD=.*|OPENCLAW_PASSWORD=$OPENCLAW_PASS|" .env

# Add OMNIROUTE_API_KEY if not present
if ! grep -q "^OMNIROUTE_API_KEY=" .env; then
    echo "" >> .env
    echo "# Auto-generated OmniRoute API Key" >> .env
    echo "OMNIROUTE_API_KEY=$OMNIROUTE_KEY" >> .env
else
    sed -i "s|OMNIROUTE_API_KEY=.*|OMNIROUTE_API_KEY=$OMNIROUTE_KEY|" .env
fi

print_success "Secrets generated successfully"
echo ""
echo "📋 Generated secrets:"
echo "   • STORAGE_ENCRYPTION_KEY: ${STORAGE_KEY:0:16}..."
echo "   • JWT_SECRET: ${JWT_SECRET:0:16}..."
echo "   • API_KEY_SECRET: ${API_SECRET:0:16}..."
echo "   • OPENCLAW_PASSWORD: $OPENCLAW_PASS"
echo "   • OMNIROUTE_API_KEY: $OMNIROUTE_KEY"
echo ""
print_info "Secrets saved to .env file"
