#!/usr/bin/env bash
#
# start-monitoring.sh - Start monitoring stack (Prometheus + Grafana)
#
# Usage:
#   ./start-monitoring.sh [--stop|--restart|--status]
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_help() {
    cat << EOF
Usage: ./start-monitoring.sh [COMMAND]

Commands:
  start     Start monitoring stack (default)
  stop      Stop monitoring stack
  restart   Restart monitoring stack
  status    Show monitoring stack status
  help      Show this help message

The monitoring stack includes:
  - Prometheus (metrics collection)
  - Grafana (visualization)
  - Redis Exporter (Redis metrics)

Access:
  - Grafana: http://localhost:3000 (admin/admin)
  - Prometheus: http://localhost:9090

EOF
    exit 0
}

start_monitoring() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Starting Monitoring Stack                         ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    log_info "Starting Prometheus, Grafana, and Redis Exporter..."
    
    # Start monitoring services
    docker compose --profile monitoring up -d
    
    echo ""
    log_success "Monitoring stack started!"
    echo ""
    echo "Access your monitoring tools:"
    echo ""
    echo "  📊 Grafana:    http://localhost:3000"
    echo "     Username:   admin"
    echo "     Password:   admin (change on first login)"
    echo ""
    echo "  📈 Prometheus: http://localhost:9090"
    echo ""
    echo "  🔍 Redis Metrics: http://localhost:9121/metrics"
    echo ""
    log_info "Grafana dashboards are pre-configured and ready to use!"
    echo ""
}

stop_monitoring() {
    echo ""
    log_info "Stopping monitoring stack..."
    
    docker compose --profile monitoring down
    
    log_success "Monitoring stack stopped"
    echo ""
}

restart_monitoring() {
    echo ""
    log_info "Restarting monitoring stack..."
    
    docker compose --profile monitoring restart
    
    log_success "Monitoring stack restarted"
    echo ""
}

show_status() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Monitoring Stack Status                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Check if monitoring containers are running
    PROMETHEUS_STATUS=$(docker ps --filter "name=omniroute-prometheus" --format "{{.Status}}" 2>/dev/null || echo "Not running")
    GRAFANA_STATUS=$(docker ps --filter "name=omniroute-grafana" --format "{{.Status}}" 2>/dev/null || echo "Not running")
    REDIS_EXPORTER_STATUS=$(docker ps --filter "name=omniroute-redis-exporter" --format "{{.Status}}" 2>/dev/null || echo "Not running")
    
    echo "Prometheus:     $PROMETHEUS_STATUS"
    echo "Grafana:        $GRAFANA_STATUS"
    echo "Redis Exporter: $REDIS_EXPORTER_STATUS"
    echo ""
    
    if docker ps | grep -q "omniroute-prometheus"; then
        log_success "Monitoring stack is running"
        echo ""
        echo "Access URLs:"
        echo "  Grafana:    http://localhost:3000"
        echo "  Prometheus: http://localhost:9090"
        echo ""
    else
        log_info "Monitoring stack is not running"
        echo ""
        echo "Start with: ./start-monitoring.sh start"
        echo ""
    fi
}

# Main
COMMAND="${1:-start}"

case "$COMMAND" in
    start)
        start_monitoring
        ;;
    stop)
        stop_monitoring
        ;;
    restart)
        restart_monitoring
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $COMMAND"
        show_help
        ;;
esac
