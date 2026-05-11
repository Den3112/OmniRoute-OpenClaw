#!/bin/bash
# Backup data and configuration for OmniRoute-OpenClaw
# Usage: ./backup.sh [--retention-days N] [--backup-dir PATH]

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

# Default settings
BACKUP_DIR="./backups"
RETENTION_DAYS=7
RETENTION_COUNT=10

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --retention-days)
            RETENTION_DAYS="$2"
            shift 2
            ;;
        --retention-count)
            RETENTION_COUNT="$2"
            shift 2
            ;;
        --backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --retention-days N    Keep backups for N days (default: 7)"
            echo "  --retention-count N   Keep last N backups (default: 10)"
            echo "  --backup-dir PATH     Backup directory (default: ./backups)"
            echo "  --help, -h            Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "💾 OmniRoute-OpenClaw Backup Utility"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_NAME="omniroute-backup-$TIMESTAMP"
BACKUP_FILE="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
BACKUP_MANIFEST="$BACKUP_DIR/$BACKUP_NAME.manifest"

print_info "Backup configuration:"
echo "  • Backup directory: $BACKUP_DIR"
echo "  • Retention: $RETENTION_DAYS days / $RETENTION_COUNT backups"
echo "  • Timestamp: $TIMESTAMP"
echo ""

# Check if containers are running
print_info "Checking container status..."
CONTAINERS_RUNNING=0
if docker ps --filter "name=omniroute" --filter "name=openclaw" --filter "name=redis" --format "{{.Names}}" 2>/dev/null | grep -q .; then
    CONTAINERS_RUNNING=1
    print_warning "Containers are running - backup will be consistent but may include in-flight data"
else
    print_info "Containers are stopped - backup will be fully consistent"
fi
echo ""

# Create manifest
print_info "Creating backup manifest..."
cat > "$BACKUP_MANIFEST" <<EOF
# OmniRoute-OpenClaw Backup Manifest
Backup Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
Backup Name: $BACKUP_NAME
Hostname: $(hostname)
Containers Running: $CONTAINERS_RUNNING

# Contents:
EOF

echo "Creating backup..."
echo "  • Data directory: ./data/"
echo "  • Configuration: .env"
echo "  • Docker compose: docker-compose.yml"
echo "  • Submodule refs: .gitmodules"
echo ""

# Create backup with progress
tar -czf "$BACKUP_FILE" \
    --exclude='./data/*/logs/*.log' \
    --exclude='./data/*/cache/*' \
    --exclude='./data/*/.next/cache' \
    --exclude='./data/*/node_modules' \
    ./data/ \
    .env \
    docker-compose.yml \
    .gitmodules \
    2>/dev/null

if [ $? -eq 0 ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    
    # Add file list to manifest
    echo "" >> "$BACKUP_MANIFEST"
    echo "# Backup Contents:" >> "$BACKUP_MANIFEST"
    tar -tzf "$BACKUP_FILE" | head -20 >> "$BACKUP_MANIFEST"
    echo "..." >> "$BACKUP_MANIFEST"
    
    # Calculate checksum
    print_info "Calculating checksum..."
    if command -v sha256sum >/dev/null 2>&1; then
        CHECKSUM=$(sha256sum "$BACKUP_FILE" | awk '{print $1}')
        echo "" >> "$BACKUP_MANIFEST"
        echo "# Integrity:" >> "$BACKUP_MANIFEST"
        echo "SHA256: $CHECKSUM" >> "$BACKUP_MANIFEST"
    fi
    
    print_success "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"
    print_success "Manifest: $BACKUP_MANIFEST"
    echo ""
    echo "To restore this backup:"
    echo "  ./restore.sh $BACKUP_FILE"
else
    print_error "Backup failed"
    rm -f "$BACKUP_FILE" "$BACKUP_MANIFEST"
    exit 1
fi

# List all backups
echo ""
echo "📋 Available backups:"
if ls "$BACKUP_DIR"/*.tar.gz >/dev/null 2>&1; then
    ls -lht "$BACKUP_DIR"/*.tar.gz | head -10 | awk '{print "  " $9 " (" $5 ", " $6 " " $7 " " $8 ")"}'
    
    TOTAL_BACKUPS=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo ""
    echo "  Total: $TOTAL_BACKUPS backups, $TOTAL_SIZE"
else
    echo "  No backups found"
fi

# Cleanup old backups by count
echo ""
print_info "Applying retention policy..."

BACKUP_COUNT=$(ls -1 "$BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$RETENTION_COUNT" ]; then
    REMOVE_COUNT=$((BACKUP_COUNT - RETENTION_COUNT))
    print_warning "Removing $REMOVE_COUNT old backups (keeping last $RETENTION_COUNT)..."
    ls -t "$BACKUP_DIR"/*.tar.gz | tail -n +$((RETENTION_COUNT + 1)) | while read file; do
        echo "  Removing: $(basename "$file")"
        rm -f "$file"
        rm -f "${file%.tar.gz}.manifest"
    done
fi

# Cleanup old backups by age
if [ "$RETENTION_DAYS" -gt 0 ]; then
    print_info "Removing backups older than $RETENTION_DAYS days..."
    find "$BACKUP_DIR" -name "omniroute-backup-*.tar.gz" -type f -mtime +$RETENTION_DAYS -exec rm -f {} \; 2>/dev/null || true
    find "$BACKUP_DIR" -name "omniroute-backup-*.manifest" -type f -mtime +$RETENTION_DAYS -exec rm -f {} \; 2>/dev/null || true
fi

print_success "Backup completed successfully!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
