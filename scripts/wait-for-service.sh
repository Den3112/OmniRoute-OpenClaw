#!/bin/bash
# wait-for-service.sh - Wait for a service to become available
# Usage: ./scripts/wait-for-service.sh <url> [timeout_seconds]

set -e

URL="${1:-http://localhost:20128/api/health}"
TIMEOUT="${2:-60}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

echo "⏳ Waiting for service: $URL"
echo "   Timeout: ${TIMEOUT}s"

WAITED=0
while [ $WAITED -lt $TIMEOUT ]; do
    if curl -s -f "$URL" > /dev/null 2>&1; then
        echo ""
        print_success "Service is ready!"
        exit 0
    fi
    
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

echo ""
print_error "Service did not become ready within ${TIMEOUT}s"
exit 1
