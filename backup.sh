#!/bin/bash
# Backup data and configuration

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }

echo "💾 Backup Utility"
echo ""

# Create backup directory
BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup-$TIMESTAMP.tar.gz"

echo "Creating backup..."
echo "  • Data directory: ./data/"
echo "  • Configuration: .env"
echo "  • Docker compose: docker-compose.yml"
echo ""

# Create backup
tar -czf "$BACKUP_FILE" \
    --exclude='./data/*/logs' \
    --exclude='./data/*/cache' \
    ./data/ \
    .env \
    docker-compose.yml \
    2>/dev/null

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    print_success "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"
    echo ""
    echo "To restore this backup:"
    echo "  ./restore.sh $BACKUP_FILE"
else
    echo "❌ Backup failed"
    exit 1
fi

# List all backups
echo ""
echo "📋 Available backups:"
ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

# Cleanup old backups (keep last 5)
BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt 5 ]; then
    print_info "Cleaning up old backups (keeping last 5)..."
    ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +6 | xargs rm -f
fi
