#!/bin/bash
# Credentials & Data Manager for OmniRoute-OpenClaw
set -e

BACKUP_DIR="./backups"
DATA_DIR="./data"
ENV_FILE=".env"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/creds_backup_$TIMESTAMP.tar.gz"

show_help() {
    echo "Usage: ./manage_creds.sh [backup|restore <file>]"
    echo ""
    echo "Commands:"
    echo "  backup         Create a backup of .env and data directory"
    echo "  restore <file> Restore from a backup file"
}

backup() {
    echo "📦 Creating backup..."
    mkdir -p "$BACKUP_DIR"
    
    if [ ! -f "$ENV_FILE" ] && [ ! -d "$DATA_DIR" ]; then
        echo "❌ Nothing to backup! (.env and ./data missing)"
        exit 1
    fi

    # Create archive
    tar -czf "$BACKUP_FILE" "$ENV_FILE" "$DATA_DIR" 2>/dev/null || {
        # If some files are missing, just archive what we have
        tar -czf "$BACKUP_FILE" $([ -f "$ENV_FILE" ] && echo "$ENV_FILE") $([ -d "$DATA_DIR" ] && echo "$DATA_DIR")
    }
    
    echo "✅ Backup created: $BACKUP_FILE"
}

restore() {
    local file=$1
    if [ -z "$file" ]; then
        echo "❌ Please specify a backup file to restore from."
        show_help
        exit 1
    fi

    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file"
        exit 1
    fi

    echo "⚠️  WARNING: This will overwrite your current .env and ./data directory!"
    read -p "Are you sure you want to proceed? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "Aborted."
        exit 0
    fi

    echo "📂 Restoring from $file..."
    tar -xzf "$file"
    echo "✅ Restore complete!"
    echo "🚀 Run 'bash update.sh' to apply changes."
}

case "$1" in
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    *)
        show_help
        ;;
esac
