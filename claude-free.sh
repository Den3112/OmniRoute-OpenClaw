#!/bin/bash
# Запуск Claude Code через локальный агрегатор OmniRoute
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 22.22.2 > /dev/null

export CLAUDE_CODE_API_URL="http://localhost:20128/v1"
export CLAUDE_CODE_API_KEY="sk-omniroute-any-key"
claude "$@"
