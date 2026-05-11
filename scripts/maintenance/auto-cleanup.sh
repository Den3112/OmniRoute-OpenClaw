#!/bin/bash
# auto-cleanup.sh - Automatic cleanup script for free-ai-aggregator
# Run daily via cron to maintain disk space

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LOG_FILE="${PROJECT_ROOT}/data/cleanup.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

log() {
    echo "[${TIMESTAMP}] $*" | tee -a "${LOG_FILE}"
}

log "=== Starting automatic cleanup ==="

# Track freed space
INITIAL_SIZE=$(du -sb "${PROJECT_ROOT}" 2>/dev/null | awk '{print $1}')

# 1. Clean old OmniRoute logs (keep last 3 days)
log "Cleaning OmniRoute logs older than 3 days..."
LOGS_DELETED=0
if [ -d "${PROJECT_ROOT}/OmniRoute/logs/application" ]; then
    LOGS_DELETED=$(find "${PROJECT_ROOT}/OmniRoute/logs/application" -name "*.log" -mtime +3 -delete -print | wc -l)
    log "Deleted ${LOGS_DELETED} old log files"
fi

# 2. Clean old DB backups (keep last 5)
log "Cleaning old database backups (keeping 5 newest)..."
DB_BACKUPS_DIR="${PROJECT_ROOT}/data/omniroute/db_backups"
if [ -d "${DB_BACKUPS_DIR}" ]; then
    BEFORE_COUNT=$(ls -1 "${DB_BACKUPS_DIR}"/*.sqlite 2>/dev/null | wc -l)
    ls -t "${DB_BACKUPS_DIR}"/*.sqlite 2>/dev/null | tail -n +6 | xargs -r rm -f
    AFTER_COUNT=$(ls -1 "${DB_BACKUPS_DIR}"/*.sqlite 2>/dev/null | wc -l)
    log "DB backups: ${BEFORE_COUNT} -> ${AFTER_COUNT} (deleted $((BEFORE_COUNT - AFTER_COUNT)))"
fi

# 3. Clean Docker build cache (if Docker available)
if command -v docker &> /dev/null; then
    log "Cleaning Docker build cache..."
    docker builder prune -f --filter "until=168h" 2>&1 | grep -i "reclaimed" | tee -a "${LOG_FILE}" || true
fi

# 4. Clean old project backups (keep last 3)
log "Cleaning old project backups (keeping 3 newest)..."
BACKUPS_DIR="${PROJECT_ROOT}/backups"
if [ -d "${BACKUPS_DIR}" ]; then
    BEFORE_BACKUPS=$(find "${BACKUPS_DIR}" -name "*.tar.gz" 2>/dev/null | wc -l)
    find "${BACKUPS_DIR}" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true
    AFTER_BACKUPS=$(find "${BACKUPS_DIR}" -name "*.tar.gz" 2>/dev/null | wc -l)
    log "Project backups: ${BEFORE_BACKUPS} -> ${AFTER_BACKUPS}"
fi

# 5. Clean scratch directory
log "Cleaning scratch directory..."
if [ -d "${PROJECT_ROOT}/scratch" ]; then
    SCRATCH_SIZE_BEFORE=$(du -sh "${PROJECT_ROOT}/scratch" 2>/dev/null | awk '{print $1}')
    find "${PROJECT_ROOT}/scratch" -type f -mtime +1 -delete 2>/dev/null || true
    SCRATCH_SIZE_AFTER=$(du -sh "${PROJECT_ROOT}/scratch" 2>/dev/null | awk '{print $1}')
    log "Scratch: ${SCRATCH_SIZE_BEFORE} -> ${SCRATCH_SIZE_AFTER}"
fi

# 6. Clean npm/pnpm cache (if exists)
if [ -d "${HOME}/.npm/_cacache" ]; then
    log "Cleaning npm cache..."
    npm cache clean --force 2>&1 | tee -a "${LOG_FILE}" || true
fi

# Calculate freed space
FINAL_SIZE=$(du -sb "${PROJECT_ROOT}" 2>/dev/null | awk '{print $1}')
FREED_BYTES=$((INITIAL_SIZE - FINAL_SIZE))
FREED_MB=$((FREED_BYTES / 1024 / 1024))

log "=== Cleanup complete ==="
log "Space freed: ${FREED_MB} MB"
log "Project size: $(du -sh "${PROJECT_ROOT}" 2>/dev/null | awk '{print $1}')"

# Cleanup old log entries (keep last 1000 lines)
if [ -f "${LOG_FILE}" ]; then
    tail -n 1000 "${LOG_FILE}" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "${LOG_FILE}"
fi

exit 0
