#!/usr/bin/env bash
set -euo pipefail

# Simple helper to run the AurumHarmony test suite.
# Usage: ./scripts/run_tests.sh

if [ -f ".venv/bin/activate" ]; then
  # shellcheck disable=SC1091
  source .venv/bin/activate
fi

pytest


