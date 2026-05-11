#!/bin/bash
# setup-opencode-mcp.sh - Configure OpenCode MCP integration with OmniRoute
# Usage: ./scripts/setup-opencode-mcp.sh

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓${NC} $1"; }
print_info() { echo -e "${YELLOW}ℹ${NC} $1"; }
print_step() { echo -e "${BLUE}==>${NC} $1"; }

print_step "Configuring OpenCode MCP integration..."

# Get absolute path to installation directory
INSTALL_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Check if OmniRoute directory exists
if [ ! -d "$INSTALL_DIR/OmniRoute/open-sse/mcp-server" ]; then
    echo "ERROR: OmniRoute MCP server not found at $INSTALL_DIR/OmniRoute/open-sse/mcp-server"
    exit 1
fi

# Create global OpenCode configuration
print_step "Creating global OpenCode MCP configuration..."
mkdir -p ~/.config/opencode

cat > ~/.config/opencode/mcp-servers.json << EOF
{
  "mcpServers": {
    "omniroute-memory": {
      "command": "npx",
      "args": [
        "tsx",
        "$INSTALL_DIR/OmniRoute/open-sse/mcp-server/server.ts"
      ],
      "env": {
        "OMNIROUTE_BASE_URL": "http://localhost:20128",
        "OMNIROUTE_API_KEY": "",
        "OMNIROUTE_MCP_ENFORCE_SCOPES": "false"
      }
    }
  }
}
EOF

print_success "Global configuration created: ~/.config/opencode/mcp-servers.json"

# Create project-local OpenCode configuration
print_step "Creating project-local OpenCode MCP configuration..."
mkdir -p "$INSTALL_DIR/.opencode"

cat > "$INSTALL_DIR/.opencode/mcp-servers.json" << EOF
{
  "mcpServers": {
    "omniroute-memory": {
      "command": "npx",
      "args": [
        "tsx",
        "$INSTALL_DIR/OmniRoute/open-sse/mcp-server/server.ts"
      ],
      "env": {
        "OMNIROUTE_BASE_URL": "http://localhost:20128",
        "OMNIROUTE_API_KEY": "",
        "OMNIROUTE_MCP_ENFORCE_SCOPES": "false"
      }
    }
  }
}
EOF

print_success "Project configuration created: .opencode/mcp-servers.json"

# Create session context file
print_step "Creating session context file..."
cat > "$INSTALL_DIR/.opencode/SESSION_CONTEXT.md" << 'EOF'
# 📝 Session Context: OmniRoute + OpenClaw

**Last Updated**: $(date -u +"%Y-%m-%d %H:%M UTC")

## 🎯 Project

**Name**: OmniRoute + OpenClaw  
**Description**: AI Gateway with 160+ providers + Memory Management  
**Port**: 20128 (OmniRoute), 18789 (OpenClaw)  
**Status**: ✅ Running

## 🔧 Configuration

### OmniRoute
- **URL**: http://localhost:20128
- **Dashboard**: http://localhost:20128/dashboard
- **Memory**: http://localhost:20128/dashboard/memory
- **Memory Management**: Enabled
- **Max Tokens**: 2000
- **Retention**: 30 days
- **Strategy**: hybrid

### OpenClaw
- **URL**: http://localhost:18789
- **Gateway**: Configured to use OmniRoute

### MCP Server
- **Path**: OmniRoute/open-sse/mcp-server/server.ts
- **Transport**: stdio
- **Tools**: 30+ (including 3 memory tools)

## 💡 Quick Commands

### Check Status
```bash
docker ps
docker compose logs -f
```

### Restart Services
```bash
./restart.sh
```

### View Memory
```bash
docker exec omniroute node -e "
const db = require('better-sqlite3')('/app/data/storage.sqlite');
const memories = db.prepare('SELECT * FROM memories ORDER BY created_at DESC LIMIT 10').all();
console.log(JSON.stringify(memories, null, 2));
"
```

### Dashboard
- OmniRoute: http://localhost:20128/dashboard
- Memory: http://localhost:20128/dashboard/memory

## 📚 Documentation

- `INTEGRATION_COMPLETE.md` - OpenCode Memory integration
- `QUICK_DEPLOY.md` - Quick deployment guide
- `README.md` - Main documentation

---

**Created**: $(date -u +"%Y-%m-%d %H:%M UTC")
EOF

print_success "Session context created: .opencode/SESSION_CONTEXT.md"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║          ✅ OpenCode MCP Configuration Complete            ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next steps:"
echo "   1. Restart OpenCode to load MCP server"
echo "   2. Check available tools: 'Какие MCP инструменты доступны?'"
echo "   3. Test memory: 'Запомни, что этот проект называется OmniRoute'"
echo ""
echo "📚 Documentation:"
echo "   • Global config: ~/.config/opencode/mcp-servers.json"
echo "   • Project config: .opencode/mcp-servers.json"
echo "   • Session context: .opencode/SESSION_CONTEXT.md"
echo ""
print_success "OpenCode MCP integration configured successfully!"
