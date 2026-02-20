import { readFileSync, existsSync } from "node:fs";
import { createSubsystemLogger } from "../logging/subsystem.js";

const log = createSubsystemLogger("secrets");
const cache = new Map<string, string | undefined>();

/**
 * Reads a secret from Docker Swarm secrets (/run/secrets/) or falls back to ENV.
 * 
 * Priority:
 * 1. Docker Secret file (/run/secrets/secret_name)
 * 2. Environment variable (SECRET_NAME)
 * 
 * @param name - Secret name (e.g., "anthropic_api_key")
 * @returns Secret value or undefined
 */
export function getSecret(name: string): string | undefined {
  if (cache.has(name)) {
    return cache.get(name);
  }

  const secretPath = `/run/secrets/${name}`;
  
  // Try Docker Secret first
  if (existsSync(secretPath)) {
    try {
      const value = readFileSync(secretPath, "utf8").trim();
      if (value) {
        log.info(`secret: ${name} loaded from Docker secret`);
        cache.set(name, value);
        return value;
      }
    } catch (err) {
      log.error(`failed to read Docker secret ${name}:`, err);
    }
  }

  // Fallback to ENV (for dev environments)
  const envKey = name.toUpperCase().replace(/-/g, "_");
  const envValue = process.env[envKey];
  if (envValue?.trim()) {
    log.info(`secret: ${name} loaded from ENV (dev mode)`);
    cache.set(name, envValue);
    return envValue;
  }

  cache.set(name, undefined);
  return undefined;
}

/**
 * Pre-loaded secrets for common use cases.
 * Add more secrets here as needed.
 */
export const secrets = {
  // AI Provider Keys
  ANTHROPIC_API_KEY: getSecret("anthropic_api_key"),
  ANTHROPIC_ADMIN_KEY: getSecret("anthropic_admin_key"),
  OPENAI_API_KEY: getSecret("openai_api_key"),
  GEMINI_API_KEY: getSecret("gemini_api_key"),
  
  // TTS Provider Keys
  ELEVENLABS_API_KEY: getSecret("elevenlabs_api_key"),
  XI_API_KEY: getSecret("xi_api_key"),
  
  // Integration Keys
  NOTION_TOKEN: getSecret("notion_token"),
  GITHUB_PAT: getSecret("github_pat"),
  CONFLUENCE_PAT: getSecret("confluence_pat"),
  CONFLUENCE_BASE_URL: getSecret("confluence_base_url"),
  CONFLUENCE_EMAIL: getSecret("confluence_email"),
  HUBSPOT_API_KEY: getSecret("hubspot_api_key"),
  
  // Chat Platform Tokens
  TELEGRAM_BOT_TOKEN: getSecret("telegram_bot_token"),
  DISCORD_BOT_TOKEN: getSecret("discord_bot_token"),
  SLACK_BOT_TOKEN: getSecret("slack_bot_token"),
  SLACK_APP_TOKEN: getSecret("slack_app_token"),
  
  // Google Services
  GMAIL_ASSISTANT_CREDENTIALS: getSecret("gmail_assistant_credentials"),
  GMAIL_ASSISTANT_TOKEN: getSecret("gmail_assistant_token"),
  GOOGLE_CALENDAR_CREDENTIALS: getSecret("google_calendar_credentials"),
  GOOGLE_CALENDAR_TOKEN: getSecret("google_calendar_token"),
  
  // Other Services
  CHATGPT_COOKIES: getSecret("chatgpt_cookies"),
  ALLOWED_USER_IDS: getSecret("allowed_user_ids"),
} as const;

/**
 * Clear the secrets cache.
 * Useful for testing or when secrets are rotated.
 */
export function clearSecretsCache(): void {
  cache.clear();
  log.info("secrets cache cleared");
}
