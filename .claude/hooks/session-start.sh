#!/bin/bash
# SessionStart hook for Claude Code cloud sessions.
# Installs this clone as a local plugin (the 9 ig-* skills) and a .venv with the
# pinned runtime deps. It never publishes, never calls Publora/Apify/Pixfaro, and
# never reads or writes .env: credentials stay where the user puts them.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

ROOT="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
cd "$ROOT"

# 1. Plugin: register the local clone as a marketplace, then install or refresh.
if claude plugin marketplace list 2>/dev/null | grep -q "Folder ($ROOT)"; then
  claude plugin marketplace update instagram-skills >/dev/null
else
  claude plugin marketplace add "$ROOT" >/dev/null
fi
if claude plugin list 2>/dev/null | grep -q "instagram-skills@instagram-skills"; then
  claude plugin update instagram-skills@instagram-skills >/dev/null || true
else
  claude plugin install instagram-skills@instagram-skills >/dev/null
fi

# 2. Python: pinned runtime deps, plus PyYAML for scripts/check_frontmatter.py.
if [ ! -x .venv/bin/python ]; then
  python3 -m venv .venv
fi
.venv/bin/pip install -q --disable-pip-version-check -r requirements-lock.txt pyyaml==6.0.3

# 3. Make `python3` resolve to the venv for the rest of the session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$ROOT/.venv/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

echo "instagram-skills: plugin and .venv ready"
