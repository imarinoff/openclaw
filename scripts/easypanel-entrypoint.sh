#!/usr/bin/env bash
# EasyPanel / Docker first-boot entrypoint for the OpenClaw gateway.
#
# On the very first start (no openclaw.json yet), this script writes a minimal
# config from environment variables so the gateway is usable without any manual
# file editing.  On subsequent starts the existing file is left untouched.
#
# Supported bootstrap env vars:
#   OPENCLAW_BROWSER_CDP_URL   - Full HTTP URL of the Chromium CDP endpoint
#                                (e.g. http://openclaw-browser:9222).
#                                Writes browser.cdpUrl into openclaw.json.
#
# All other runtime env vars (OPENCLAW_GATEWAY_TOKEN, OPENAI_API_KEY, channel
# tokens, etc.) are consumed directly by the gateway process without needing to
# appear in openclaw.json.
set -euo pipefail

HOME="${HOME:-/home/node}"
OPENCLAW_STATE_DIR="${OPENCLAW_STATE_DIR:-${HOME}/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-${OPENCLAW_STATE_DIR}/openclaw.json}"

mkdir -p "${OPENCLAW_STATE_DIR}"
chmod 700 "${OPENCLAW_STATE_DIR}"

if [ ! -f "${CONFIG_PATH}" ]; then
  echo "OpenClaw: bootstrapping initial config from environment..."
  node - <<'NODEEOF'
const fs   = require('fs');
const path = require('path');

const home       = process.env.HOME || '/home/node';
const stateDir   = process.env.OPENCLAW_STATE_DIR  || path.join(home, '.openclaw');
const configPath = process.env.OPENCLAW_CONFIG_PATH || path.join(stateDir, 'openclaw.json');

const cfg = {
  gateway: { mode: 'local' },
};

const cdpUrl = (process.env.OPENCLAW_BROWSER_CDP_URL || '').trim();
if (cdpUrl) {
  cfg.browser = { cdpUrl };
}

fs.writeFileSync(configPath, JSON.stringify(cfg, null, 2) + '\n', { mode: 0o600 });
console.log('OpenClaw: config written to ' + configPath);
NODEEOF
fi

exec "$@"
