#!/bin/bash
# Restore data and configuration from backup

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_error() { echo -e "${RED}✗${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }

echo "♻️  Restore Utility"
echo ""

# Check if backup file provided
if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <backup-file>"
    echo ""
    echo "Available backups:"
    ls -lh ./backups/*.tar.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup exists
if [ ! -f "$BACKUP_FILE" ]; then
    print_error "Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "Backup file: $BACKUP_FILE"
echo ""
print_warning "This will:"
echo "  • Stop all running containers"
echo "  • Replace current data with backup"
echo "  • Replace .env and docker-compose.yml"
echo ""

read -p "Continue? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

echo ""
echo "🛑 Stopping containers..."
docker compose down

echo ""
echo "📦 Extracting backup..."
tar -xzf "$BACKUP_FILE" -C .

if [ $? -eq 0 ]; then
    print_success "Backup restored successfully"
    echo ""
    echo "🚀 Starting containers..."
    docker compose up -d
    echo ""
    print_success "Restore complete!"
    echo ""
    echo "Check status: ./status.sh"
else
    print_error "Restore failed"
    exit 1
fi
