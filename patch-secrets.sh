#!/bin/bash
# Автоматический патч для замены process.env.* на secrets.*

set -e

FILES=(
  "src/channels/plugins/onboarding/discord.ts"
  "src/channels/plugins/onboarding/slack.ts"
  "src/channels/plugins/onboarding/telegram.ts"
  "src/commands/auth-choice.apply.anthropic.ts"
  "src/commands/auth-choice.apply.openai.ts"
  "src/commands/onboard-non-interactive/local/auth-choice.ts"
  "src/config/defaults.ts"
  "src/logging/subsystem.ts"
  "src/security/audit-extra.async.ts"
  "src/slack/accounts.ts"
  "src/tts/tts-core.ts"
)

echo "=== Патчинг файлов ==="

for file in "${FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "⚠️  Файл не найден: $file"
    continue
  fi
  
  echo "📝 Патчинг: $file"
  
  # Добавляем импорт secrets если его нет
  if ! grep -q "import.*secrets.*from.*infra/secrets" "$file"; then
    # Находим последний импорт и добавляем после него
    sed -i '' '/^import.*from.*"\.\..*";$/a\
import { secrets } from "../infra/secrets.js";
' "$file" 2>/dev/null || true
  fi
  
  # Заменяем process.env.* на secrets.*
  sed -i '' 's/process\.env\.ANTHROPIC_API_KEY/secrets.ANTHROPIC_API_KEY/g' "$file"
  sed -i '' 's/process\.env\.ANTHROPIC_ADMIN_KEY/secrets.ANTHROPIC_ADMIN_KEY/g' "$file"
  sed -i '' 's/process\.env\.OPENAI_API_KEY/secrets.OPENAI_API_KEY/g' "$file"
  sed -i '' 's/process\.env\.GEMINI_API_KEY/secrets.GEMINI_API_KEY/g' "$file"
  sed -i '' 's/process\.env\.NOTION_TOKEN/secrets.NOTION_TOKEN/g' "$file"
  sed -i '' 's/process\.env\.GITHUB_PAT/secrets.GITHUB_PAT/g' "$file"
  sed -i '' 's/process\.env\.TELEGRAM_BOT_TOKEN/secrets.TELEGRAM_BOT_TOKEN/g' "$file"
  sed -i '' 's/process\.env\.DISCORD_BOT_TOKEN/secrets.DISCORD_BOT_TOKEN/g' "$file"
  sed -i '' 's/process\.env\.SLACK_BOT_TOKEN/secrets.SLACK_BOT_TOKEN/g' "$file"
  sed -i '' 's/process\.env\.SLACK_APP_TOKEN/secrets.SLACK_APP_TOKEN/g' "$file"
  sed -i '' 's/process\.env\.CONFLUENCE_PAT/secrets.CONFLUENCE_PAT/g' "$file"
  sed -i '' 's/process\.env\.HUBSPOT_API_KEY/secrets.HUBSPOT_API_KEY/g' "$file"
  sed -i '' 's/process\.env\.GMAIL_/secrets.GMAIL_/g' "$file"
  sed -i '' 's/process\.env\.GOOGLE_/secrets.GOOGLE_/g' "$file"
  sed -i '' 's/process\.env\.CHATGPT_/secrets.CHATGPT_/g' "$file"
  sed -i '' 's/process\.env\.ELEVENLABS_API_KEY/secrets.ELEVENLABS_API_KEY/g' "$file"
  sed -i '' 's/process\.env\.XI_API_KEY/secrets.XI_API_KEY/g' "$file"
  
  echo "✅ Готово: $file"
done

echo ""
echo "=== Проверка изменений ==="
git diff --stat

echo ""
echo "✅ Патч завершён!"
