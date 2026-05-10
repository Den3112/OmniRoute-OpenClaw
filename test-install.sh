#!/bin/bash
# 🧪 OmniRoute-OpenClaw Installation Test Script
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() { echo -e "\n${BLUE}==>${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }

TEST_DIR="/tmp/omniroute-test-$(date +%s)"

echo "🚀 Starting Installation Test..."
echo "📂 Test Directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    print_step "Cleaning up..."
    cd /
    rm -rf "$TEST_DIR"
    print_success "Cleanup complete"
}
trap cleanup EXIT

# 1. Create test directory and clone
print_step "Cloning repository..."
mkdir -p "$TEST_DIR"
git clone --recursive . "$TEST_DIR"
cd "$TEST_DIR"
print_success "Repository cloned"

# 2. Check secret generation
print_step "Testing secret generation..."
chmod +x update.sh
# Mock docker-compose to avoid full installation during secret test
mkdir -p bin
cat <<EOF > bin/docker-compose
#!/bin/bash
echo "Mock docker-compose called with: \$@"
EOF
cat <<EOF > bin/docker
#!/bin/bash
if [[ "\$*" == "compose version"* ]]; then
    echo "Docker Compose version v2.20.0"
elif [[ "\$*" == "version"* ]]; then
    echo "Docker version 24.0.5"
else
    echo "Mock docker called with: \$@"
fi
EOF
chmod +x bin/docker-compose bin/docker
export PATH="$TEST_DIR/bin:$PATH"

# Run update.sh but stop before docker commands
# We'll use a modified version or just check if .env is created
./update.sh --help >/dev/null 2>&1 || true # Just to trigger initial checks

if [ -f .env ]; then
    print_success ".env file created"
    for var in STORAGE_ENCRYPTION_KEY JWT_SECRET API_KEY_SECRET OPENCLAW_PASSWORD; do
        if grep -q "^$var=" .env; then
            val=$(grep "^$var=" .env | cut -d'=' -f2)
            if [ -n "$val" ] && [ "$val" != "CHANGEME" ]; then
                print_success "Secret $var generated correctly"
            else
                print_error "Secret $var is empty or default"
                exit 1
            fi
        else
            print_error "Secret $var missing in .env"
            exit 1
        fi
    done
else
    print_error ".env file not created"
    exit 1
fi

# 3. Check shell scripts syntax
print_step "Checking script syntax..."
for script in *.sh; do
    bash -n "$script"
    print_success "Syntax OK: $script"
done

print_step "Test Results"
print_success "All basic checks passed!"
echo ""
echo "Note: Full container deployment test requires a real Docker environment."
echo "Use GitHub Actions for full integration testing."
