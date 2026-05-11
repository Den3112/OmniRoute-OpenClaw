# OmniRoute-OpenClaw Architecture

This document provides a detailed description of the project's technical structure and component interactions.

## System Overview

The project is a container orchestration that provides a complete workflow for AI models: from key management to providing a high-level API gateway.

### Main Components

1.  **OmniRoute (Core/Dashboard)**:
    - Built on Node.js (Next.js).
    - Manages the database of providers and keys.
    - Provides a web interface for administration.
    - Implements quota logic, billing, and load balancing.

2.  **OpenClaw (Gateway)**:
    - Lightweight and fast gateway on Go/Node.js.
    - Optimized for streaming requests (SSE).
    - Adds an abstraction layer for "agentic" functions.

3.  **Redis**:
    - Used for caching LLM responses.
    - Stores OmniRoute user sessions.
    - Ensures high performance by minimizing disk access.

4.  **Docker Network**:
    - All services are combined in the `omniroute_net` network.
    - Direct external access is only open to Dashboard (:20128) and Gateway (:18789).

## Data Flow

When a user makes a request through the API:

1.  The request arrives at **OpenClaw Gateway**.
2.  OpenClaw checks authorization and forwards the request to **OmniRoute Core** through the internal network.
3.  OmniRoute checks for cache in **Redis**.
4.  If there is no cache, OmniRoute selects an appropriate provider (OpenAI/Anthropic/...) and makes an external request.
5.  The response is saved in Redis and returned to the user through the service chain.

## Directory Structure

- `/OmniRoute`: Aggregator source code (Git Submodule).
- `/openclaw`: Gateway source code (Git Submodule).
- `/data`: Persistent data (databases, configs).
- `/docs`: Images and additional documentation materials.
- `update.sh`: Main lifecycle management script.

## Memory Management and Skills System

### Memory Management

**Status**: ✅ Configured and working

OmniRoute includes a persistent memory system for AI agents:

- **Storage**: SQLite `memories` table with FTS5 index for full-text search
- **Memory types**: factual, episodic, procedural, semantic
- **Search strategies**: exact (chronological), semantic (FTS5), hybrid (combined)
- **Automatic extraction**: Facts are extracted from LLM responses automatically
- **Injection**: Memory is injected into system messages before sending to provider
- **Configuration**: 2000 tokens, 30 days retention, hybrid strategy

**Files**:
- `OmniRoute/src/lib/memory/` - Main implementation
- `OmniRoute/src/lib/db/migrations/015_create_memories.sql` - DB schema
- `OmniRoute/src/lib/db/migrations/022_add_memory_fts5.sql` - FTS5 index

### Skills System

**Status**: ✅ Configured and working

Extensible skills system for AI agents:

- **Built-in skills**: file_read, file_write, http_request, web_search, eval_code, execute_command
- **Sources**: SkillsMP (marketplace), Skills.sh (public catalog), Local (custom)
- **Modes**: on (always), off (disabled), auto (automatic selection based on context)
- **Sandbox**: Docker isolation with resource limits (256MB RAM, 10s timeout)
- **Installed**: 5 skills (web-search, file-reader, sql-assistant, devops-helper, docs-assistant)

**Files**:
- `OmniRoute/src/lib/skills/` - Main implementation
- `OmniRoute/src/lib/db/migrations/016_create_skills.sql` - DB schema
- `OmniRoute/src/lib/db/migrations/027_skill_mode_and_metadata.sql` - Metadata

### MCP Server Integration

**Status**: ✅ Configured and working

Model Context Protocol server with 37 tools, including:

**Memory tools** (3):
- `omniroute_memory_search` - Search memories
- `omniroute_memory_add` - Add memory
- `omniroute_memory_clear` - Clear memory

**Skills tools** (4):
- `omniroute_skills_list` - List skills
- `omniroute_skills_enable` - Enable/disable skill
- `omniroute_skills_execute` - Execute skill
- `omniroute_skills_executions` - Execution history

**Transports**: stdio, SSE, HTTP

**Files**:
- `OmniRoute/open-sse/mcp-server/` - MCP server
- `OmniRoute/open-sse/mcp-server/tools/memoryTools.ts` - Memory tools
- `OmniRoute/open-sse/mcp-server/tools/skillTools.ts` - Skills tools

### Memory & Skills Documentation

- **README_MEMORY_SKILLS.md** - Main page with setup results
- **MEMORY_SKILLS_CONFIG.md** - Complete technical documentation (500+ lines)
- **QUICKSTART_MEMORY_SKILLS.md** - Quick start with examples (400+ lines)
- **MEMORY_SKILLS_SUMMARY.md** - Detailed project summary (600+ lines)
- **test_memory_skills.sh** - Automated testing

## Security

- **Secrets**: All sensitive keys are automatically generated using `/dev/urandom` or OpenSSL on first run.
- **Isolation**: Containers run with minimal necessary privileges.
- **Logs**: Docker log rotation is configured to prevent "denial of service" attacks through disk overflow.
- **Skills Sandbox**: Skills are executed in isolated Docker containers with resource limits.
- **Memory Isolation**: Memories are isolated by API keys, each client sees only their own data.
