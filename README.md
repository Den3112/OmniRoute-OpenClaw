# OmniRoute-OpenClaw Integrated Environment

This repository contains a pre-configured, integrated environment for running **OmniRoute** and **OpenClaw** together.

## Project Structure

- `OmniRoute/`: A powerful AI model router and aggregator.
- `openclaw/`: An open-source implementation of the Claude API, allowing for agentic workflows.
- `docker-compose.yml`: Configuration for running the entire stack using Docker.
- `claude-free.sh`: Utility script for managing the environment.

## Features

- **Multi-Agent Infrastructure**: Stable, performant, and persistent deployment.
- **Optimized Performance**: SQLite WAL and Redis caching support (planned/implemented).
- **Dockerized Setup**: Portable and easy to deploy on any VPS or local machine.
- **Free AI Access**: Designed to work with free-tier AI services and aggregators.

## Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Den3112/OmniRoute-OpenClaw.git
   cd OmniRoute-OpenClaw
   ```

2. **Configure Environment Variables**:
   Copy `.env.example` files in subdirectories to `.env` and fill in your credentials.
   *Note: `.env` files are ignored by git for security.*

3. **Run with Docker**:
   ```bash
   docker-compose up -d
   ```

## Security Note

Sensitive files like `.env` and `.git` folders from submodules have been intentionally excluded from this repository to prevent credential leaks and maintain a clean structure.
