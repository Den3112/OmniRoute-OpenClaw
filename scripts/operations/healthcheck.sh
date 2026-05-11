#!/bin/bash
# Automatic Health Check and Recovery Script

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

# Detect Docker Compose command
if docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
elif docker-compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
else
    print_error "Docker Compose not found"
    exit 1
fi

echo "🏥 Health Check & Auto-Recovery"
echo ""

# Check if containers are running
print_info "Checking container status..."

OMNIROUTE_STATUS=$(docker inspect -f '{{.State.Status}}' omniroute 2>/dev/null || echo "not_found")
OPENCLAW_STATUS=$(docker inspect -f '{{.State.Status}}' openclaw 2>/dev/null || echo "not_found")
REDIS_STATUS=$(docker inspect -f '{{.State.Status}}' omniroute-redis 2>/dev/null || echo "not_found")

ISSUES=0

# Check OmniRoute
if [ "$OMNIROUTE_STATUS" = "running" ]; then
    print_success "OmniRoute is running"
    
    # Check health
    HEALTH=$(docker inspect -f '{{.State.Health.Status}}' omniroute 2>/dev/null || echo "none")
    if [ "$HEALTH" = "healthy" ]; then
        print_success "OmniRoute is healthy"
    elif [ "$HEALTH" = "unhealthy" ]; then
        print_warning "OmniRoute is unhealthy - attempting restart..."
        docker restart omniroute
        ISSUES=$((ISSUES + 1))
    fi
else
    print_error "OmniRoute is not running (status: $OMNIROUTE_STATUS)"
    ISSUES=$((ISSUES + 1))
fi

# Check OpenClaw
if [ "$OPENCLAW_STATUS" = "running" ]; then
    print_success "OpenClaw is running"
    
    HEALTH=$(docker inspect -f '{{.State.Health.Status}}' openclaw 2>/dev/null || echo "none")
    if [ "$HEALTH" = "healthy" ]; then
        print_success "OpenClaw is healthy"
    elif [ "$HEALTH" = "unhealthy" ]; then
        print_warning "OpenClaw is unhealthy - attempting restart..."
        docker restart openclaw
        ISSUES=$((ISSUES + 1))
    fi
else
    print_error "OpenClaw is not running (status: $OPENCLAW_STATUS)"
    ISSUES=$((ISSUES + 1))
fi

# Check Redis
if [ "$REDIS_STATUS" = "running" ]; then
    print_success "Redis is running"
    
    HEALTH=$(docker inspect -f '{{.State.Health.Status}}' omniroute-redis 2>/dev/null || echo "none")
    if [ "$HEALTH" = "healthy" ]; then
        print_success "Redis is healthy"
    elif [ "$HEALTH" = "unhealthy" ]; then
        print_warning "Redis is unhealthy - attempting restart..."
        docker restart omniroute-redis
        ISSUES=$((ISSUES + 1))
    fi
else
    print_error "Redis is not running (status: $REDIS_STATUS)"
    ISSUES=$((ISSUES + 1))
fi

# If any issues found, try to recover
if [ $ISSUES -gt 0 ]; then
    echo ""
    print_warning "Found $ISSUES issue(s) - attempting automatic recovery..."
    
    # Try to start all services
    $DOCKER_COMPOSE up -d
    
    echo ""
    print_info "Waiting 30 seconds for services to stabilize..."
    sleep 30
    
    # Re-check
    echo ""
    print_info "Re-checking services..."
    
    OMNIROUTE_HEALTH=$(docker inspect -f '{{.State.Health.Status}}' omniroute 2>/dev/null || echo "none")
    OPENCLAW_HEALTH=$(docker inspect -f '{{.State.Health.Status}}' openclaw 2>/dev/null || echo "none")
    REDIS_HEALTH=$(docker inspect -f '{{.State.Health.Status}}' omniroute-redis 2>/dev/null || echo "none")
    
    if [ "$OMNIROUTE_HEALTH" = "healthy" ] && [ "$OPENCLAW_HEALTH" = "healthy" ] && [ "$REDIS_HEALTH" = "healthy" ]; then
        echo ""
        print_success "All services recovered successfully!"
        exit 0
    else
        echo ""
        print_error "Some services still unhealthy. Check logs:"
        echo "   docker logs omniroute"
        echo "   docker logs openclaw"
        echo "   docker logs omniroute-redis"
        exit 1
    fi
else
    echo ""
    print_success "All services are healthy!"
    exit 0
fi
