#!/bin/sh
# OpenClaw Docker Entrypoint
# Создаёт auth-profiles.json из Docker Secrets при старте

set -e

AUTH_DIR="/home/node/.openclaw/agents/main/agent"
AUTH_FILE="$AUTH_DIR/auth-profiles.json"

# Создаём директорию если её нет
mkdir -p "$AUTH_DIR"

# Читаем ключи из Docker Secrets
ANTHROPIC_KEY=""
OPENAI_KEY=""

if [ -f "/run/secrets/anthropic_api_key" ]; then
  ANTHROPIC_KEY=$(cat /run/secrets/anthropic_api_key)
fi

if [ -f "/run/secrets/openai_api_key" ]; then
  OPENAI_KEY=$(cat /run/secrets/openai_api_key)
fi

# Создаём auth-profiles.json только если его нет
if [ ! -f "$AUTH_FILE" ]; then
  echo "Creating auth-profiles.json from Docker Secrets..."
  
  cat > "$AUTH_FILE" <<EOF
{
  "version": 1,
  "profiles": {
EOF

  # Добавляем Anthropic профиль если ключ есть
  if [ -n "$ANTHROPIC_KEY" ]; then
    cat >> "$AUTH_FILE" <<EOF
    "anthropic:default": {
      "type": "api_key",
      "provider": "anthropic",
      "key": "$ANTHROPIC_KEY"
    }
EOF
    
    # Добавляем запятую если есть OpenAI ключ
    if [ -n "$OPENAI_KEY" ]; then
      echo "," >> "$AUTH_FILE"
    fi
  fi

  # Добавляем OpenAI профиль если ключ есть
  if [ -n "$OPENAI_KEY" ]; then
    cat >> "$AUTH_FILE" <<EOF
    "openai:default": {
      "type": "api_key",
      "provider": "openai",
      "key": "$OPENAI_KEY"
    }
EOF
  fi

  # Закрываем JSON
  cat >> "$AUTH_FILE" <<EOF
  }
}
EOF

  # Устанавливаем правильные права
  chown node:node "$AUTH_FILE"
  chmod 600 "$AUTH_FILE"
  
  echo "✅ auth-profiles.json created"
else
  echo "auth-profiles.json already exists, skipping creation"
fi

# Устанавливаем Python зависимости из workspace
REQUIREMENTS_FILE="/home/node/.openclaw/workspace/requirements.txt"
if [ -f "$REQUIREMENTS_FILE" ]; then
  echo "Installing Python dependencies from workspace..."
  python3 -m pip install --quiet --no-cache-dir --break-system-packages -r "$REQUIREMENTS_FILE" 2>&1 | grep -v "already satisfied" || true
  echo "✅ Python dependencies installed"
fi

# Запускаем OpenClaw
exec "$@"
