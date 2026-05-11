#!/bin/bash
# enable-memory.sh - Enable Memory Management in OmniRoute
# Usage: ./scripts/enable-memory.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_error() { echo -e "${RED}✗${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }
print_step() { echo -e "${BLUE}==>${NC} $1"; }

print_step "Enabling Memory Management in OmniRoute..."

# Check if OmniRoute container is running
if ! docker ps | grep -q omniroute; then
    print_error "OmniRoute container is not running"
    echo "   Start services first: docker compose up -d"
    exit 1
fi

# Wait for OmniRoute to be ready
print_step "Waiting for OmniRoute to be ready..."
MAX_WAIT=60
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    if curl -s http://localhost:20128/api/health > /dev/null 2>&1; then
        print_success "OmniRoute is ready"
        break
    fi
    sleep 2
    WAITED=$((WAITED + 2))
    echo -n "."
done

if [ $WAITED -ge $MAX_WAIT ]; then
    print_error "OmniRoute did not start within ${MAX_WAIT}s"
    exit 1
fi

echo ""

# Enable Memory Management
print_step "Enabling Memory Management..."

docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');

try {
    // Enable Memory Management
    db.prepare('UPDATE key_value SET value = ? WHERE namespace = ? AND key = ?')
      .run('true', 'settings', 'memoryEnabled');
    
    // Set default configuration
    const settings = {
        memoryMaxTokens: 2000,
        memoryRetentionDays: 30,
        memoryStrategy: 'hybrid'
    };
    
    for (const [key, value] of Object.entries(settings)) {
        const existing = db.prepare('SELECT value FROM key_value WHERE namespace = ? AND key = ?')
          .get('settings', key);
        
        if (!existing) {
            db.prepare('INSERT INTO key_value (namespace, key, value) VALUES (?, ?, ?)')
              .run('settings', key, JSON.stringify(value));
        }
    }
    
    console.log('SUCCESS');
} catch (e) {
    console.error('ERROR:', e.message);
    process.exit(1);
}
" 2>&1

if [ $? -eq 0 ]; then
    print_success "Memory Management enabled"
else
    print_error "Failed to enable Memory Management"
    exit 1
fi

# Verify configuration
print_step "Verifying configuration..."

MEMORY_STATUS=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const result = db.prepare('SELECT value FROM key_value WHERE namespace = ? AND key = ?')
  .get('settings', 'memoryEnabled');
console.log(result ? result.value : 'false');
" 2>/dev/null)

if [ "$MEMORY_STATUS" = "true" ]; then
    print_success "Memory Management is enabled"
else
    print_error "Memory Management verification failed"
    exit 1
fi

# Check database tables
print_step "Checking database tables..."

TABLE_COUNT=$(docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const tables = db.prepare(\"SELECT name FROM sqlite_master WHERE type='table' AND name='memories'\").all();
console.log(tables.length);
" 2>/dev/null)

if [ "$TABLE_COUNT" -gt 0 ]; then
    print_success "Memory tables exist"
else
    print_error "Memory tables not found"
    exit 1
fi

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║         ✅ Memory Management Enabled Successfully          ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Configuration:"
echo "   • Status: Enabled"
echo "   • Max Tokens: 2000"
echo "   • Retention: 30 days"
echo "   • Strategy: hybrid (exact + semantic)"
echo ""
echo "🌐 Dashboard:"
echo "   • Memory: http://localhost:20128/dashboard/memory"
echo "   • Settings: http://localhost:20128/dashboard/settings"
echo ""
echo "💡 Test it:"
echo "   In OpenCode: 'Запомни, что этот проект называется OmniRoute'"
echo ""
print_success "Memory Management is ready to use!"
