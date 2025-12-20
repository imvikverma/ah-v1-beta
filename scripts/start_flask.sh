#!/usr/bin/env bash
set -euo pipefail

# Start the AurumHarmony Flask backend (HDFC example app).
# Usage: ./scripts/start_flask.sh

if [ -f ".venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

python config/app.py


