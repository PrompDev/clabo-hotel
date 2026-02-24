#!/bin/bash
set -euo pipefail

# Only run in remote (web) sessions
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# Install Python dependencies for utility scripts
# - pandas + openpyxl: used by arcturus/perms_sql.py for Excel processing
# - requests: used by assets/translation/external_text.py, assets/badge_name_update.py, imager/check.py
pip3 install pandas openpyxl requests
