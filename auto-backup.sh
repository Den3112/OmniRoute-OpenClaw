#!/bin/bash
# Automatic backup scheduler for OmniRoute-OpenClaw
# This script sets up automatic backups using cron or systemd timer

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

echo "⏰ OmniRoute-OpenClaw Automatic Backup Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Get current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"

# Check if backup.sh exists
if [ ! -f "$BACKUP_SCRIPT" ]; then
    print_error "backup.sh not found at $BACKUP_SCRIPT"
    exit 1
fi

# Make backup.sh executable
chmod +x "$BACKUP_SCRIPT"

# Default schedule
SCHEDULE="daily"
BACKUP_TIME="02:00"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --schedule)
            SCHEDULE="$2"
            shift 2
            ;;
        --time)
            BACKUP_TIME="$2"
            shift 2
            ;;
        --help|-h)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --schedule FREQ    Backup frequency: hourly, daily, weekly (default: daily)"
            echo "  --time HH:MM       Backup time for daily/weekly (default: 02:00)"
            echo "  --help, -h         Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                           # Daily backup at 2:00 AM"
            echo "  $0 --schedule hourly         # Hourly backups"
            echo "  $0 --schedule daily --time 03:30  # Daily at 3:30 AM"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_info "Configuration:"
echo "  • Schedule: $SCHEDULE"
echo "  • Time: $BACKUP_TIME"
echo "  • Backup script: $BACKUP_SCRIPT"
echo ""

# Detect init system
if command -v systemctl >/dev/null 2>&1 && systemctl --version >/dev/null 2>&1; then
    INIT_SYSTEM="systemd"
    print_info "Detected init system: systemd"
elif command -v crontab >/dev/null 2>&1; then
    INIT_SYSTEM="cron"
    print_info "Detected init system: cron"
else
    print_error "Neither systemd nor cron found"
    exit 1
fi

echo ""

# Setup based on init system
if [ "$INIT_SYSTEM" = "systemd" ]; then
    print_info "Setting up systemd timer..."
    
    # Create systemd service
    SERVICE_FILE="/tmp/omniroute-backup.service"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=OmniRoute-OpenClaw Backup Service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=$SCRIPT_DIR
ExecStart=$BACKUP_SCRIPT --retention-days 7 --retention-count 10
User=$USER
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Create systemd timer
    TIMER_FILE="/tmp/omniroute-backup.timer"
    
    case $SCHEDULE in
        hourly)
            TIMER_SCHEDULE="OnCalendar=hourly"
            ;;
        daily)
            HOUR=$(echo "$BACKUP_TIME" | cut -d: -f1)
            MINUTE=$(echo "$BACKUP_TIME" | cut -d: -f2)
            TIMER_SCHEDULE="OnCalendar=*-*-* ${HOUR}:${MINUTE}:00"
            ;;
        weekly)
            HOUR=$(echo "$BACKUP_TIME" | cut -d: -f1)
            MINUTE=$(echo "$BACKUP_TIME" | cut -d: -f2)
            TIMER_SCHEDULE="OnCalendar=Sun ${HOUR}:${MINUTE}:00"
            ;;
        *)
            print_error "Invalid schedule: $SCHEDULE"
            exit 1
            ;;
    esac
    
    cat > "$TIMER_FILE" <<EOF
[Unit]
Description=OmniRoute-OpenClaw Backup Timer
Requires=omniroute-backup.service

[Timer]
$TIMER_SCHEDULE
Persistent=true

[Install]
WantedBy=timers.target
EOF

    echo ""
    print_info "Systemd unit files created:"
    echo "  • Service: $SERVICE_FILE"
    echo "  • Timer: $TIMER_FILE"
    echo ""
    print_warning "To install, run as root:"
    echo "  sudo cp $SERVICE_FILE /etc/systemd/system/"
    echo "  sudo cp $TIMER_FILE /etc/systemd/system/"
    echo "  sudo systemctl daemon-reload"
    echo "  sudo systemctl enable omniroute-backup.timer"
    echo "  sudo systemctl start omniroute-backup.timer"
    echo ""
    print_info "To check status:"
    echo "  sudo systemctl status omniroute-backup.timer"
    echo "  sudo systemctl list-timers omniroute-backup.timer"
    
elif [ "$INIT_SYSTEM" = "cron" ]; then
    print_info "Setting up cron job..."
    
    # Generate cron schedule
    case $SCHEDULE in
        hourly)
            CRON_SCHEDULE="0 * * * *"
            ;;
        daily)
            HOUR=$(echo "$BACKUP_TIME" | cut -d: -f1)
            MINUTE=$(echo "$BACKUP_TIME" | cut -d: -f2)
            CRON_SCHEDULE="$MINUTE $HOUR * * *"
            ;;
        weekly)
            HOUR=$(echo "$BACKUP_TIME" | cut -d: -f1)
            MINUTE=$(echo "$BACKUP_TIME" | cut -d: -f2)
            CRON_SCHEDULE="$MINUTE $HOUR * * 0"
            ;;
        *)
            print_error "Invalid schedule: $SCHEDULE"
            exit 1
            ;;
    esac
    
    CRON_JOB="$CRON_SCHEDULE cd $SCRIPT_DIR && $BACKUP_SCRIPT --retention-days 7 --retention-count 10 >> $SCRIPT_DIR/backups/backup.log 2>&1"
    
    echo ""
    print_info "Cron job:"
    echo "  $CRON_JOB"
    echo ""
    
    # Check if cron job already exists
    if crontab -l 2>/dev/null | grep -q "omniroute-backup"; then
        print_warning "Cron job already exists"
        echo ""
        read -p "Replace existing cron job? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled"
            exit 0
        fi
        # Remove old job
        crontab -l 2>/dev/null | grep -v "omniroute-backup" | crontab -
    fi
    
    # Add new cron job
    (crontab -l 2>/dev/null; echo "# OmniRoute-OpenClaw automatic backup"; echo "$CRON_JOB") | crontab -
    
    print_success "Cron job installed!"
    echo ""
    print_info "To view cron jobs:"
    echo "  crontab -l"
    echo ""
    print_info "To remove cron job:"
    echo "  crontab -e  # and delete the omniroute-backup line"
fi

echo ""
print_success "Automatic backup setup complete!"
echo ""
print_info "Manual backup:"
echo "  $BACKUP_SCRIPT"
echo ""
print_info "Backup location:"
echo "  $SCRIPT_DIR/backups/"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
