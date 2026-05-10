#!/bin/bash
# Clean up old data, logs, and Docker resources

echo "🧹 Cleanup Utility"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_warning() { echo -e "${YELLOW}⚠${NC} $1"; }
print_success() { echo -e "${GREEN}✓${NC} $1"; }

echo "This will clean up:"
echo "  • Stopped containers"
echo "  • Unused images"
echo "  • Unused networks"
echo "  • Build cache"
echo ""
print_warning "This will NOT delete:"
echo "  • Running containers"
echo "  • Data in ./data/ directory"
echo ""

read -p "Continue? (y/N): " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "🧹 Cleaning Docker resources..."

# Remove stopped containers
docker container prune -f

# Remove unused images
docker image prune -af

# Remove unused networks
docker network prune -f

# Remove build cache
docker builder prune -f

echo ""
print_success "Cleanup complete!"

# Show disk usage
echo ""
echo "📊 Docker disk usage:"
docker system df
