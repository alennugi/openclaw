#!/bin/bash
# Исправление дублированных импортов secrets

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

echo "=== Исправление дублированных импортов ==="

for file in "${FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    continue
  fi
  
  echo "📝 Исправление: $file"
  
  # Удаляем все дублированные импорты secrets
  # Оставляем только первое вхождение
  awk '
    !seen && /^import { secrets } from "\.\.\/infra\/secrets\.js";$/ {
      print
      seen = 1
      next
    }
    /^import { secrets } from "\.\.\/infra\/secrets\.js";$/ {
      next
    }
    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  
  echo "✅ Готово: $file"
done

echo ""
echo "=== Проверка ==="
grep -c "import.*secrets.*from.*infra/secrets" src/channels/plugins/onboarding/discord.ts || echo "0"

echo ""
echo "✅ Импорты исправлены!"
