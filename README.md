# OmniRoute-OpenClaw Integrated Environment

This repository contains a pre-configured, integrated environment for running **OmniRoute** and **OpenClaw** together using Git Submodules for easy updates.

## Project Structure

- `OmniRoute/`: [Submodule] A powerful AI model router and aggregator.
- `openclaw/`: [Submodule] An open-source implementation of the Claude API.
- `docker-compose.yml`: Configuration for running the entire stack using Docker.
- `update.sh`: One-click script to update all components to their latest versions.
- `claude-free.sh`: Utility script for managing the environment.

## Getting Started

1. **Clone the repository with submodules**:
   ```bash
   git clone --recursive https://github.com/Den3112/OmniRoute-OpenClaw.git
   cd OmniRoute-OpenClaw
   ```

2. **Configure Environment Variables**:
   Ensure `.env` files exist in `OmniRoute/` and `openclaw/`.
   *Note: `.env` files are ignored by git for security.*

3. **Run with Docker**:
   ```bash
   docker-compose up -d --build
   ```

## 🔄 How to Update

To update both OmniRoute and openclaw to their latest versions and restart the system, simply run:
```bash
./update.sh
```
This script will pull the latest commits from the original repositories, rebuild the Docker images, and restart the containers.

## Security Note

Sensitive files like `.env` and internal `.git` folders are excluded or managed via submodules to maintain a clean and secure environment.
