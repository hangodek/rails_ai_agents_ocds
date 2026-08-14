#!/usr/bin/env bash
echo "[DEPRECATED] scripts/sync_claude_rules_to_copilot.sh is superseded by: ruby scripts/sync_ai_to_all.rb --target=copilot"
exec ruby "$(dirname "$0")/sync_ai_to_all.rb" --target=copilot "$@"
