#!/usr/bin/env bash
echo "[DEPRECATED] scripts/sync_claude_skills_to_codex.sh is superseded by: ruby scripts/sync_ai_to_all.rb --target=opencode"
exec ruby "$(dirname "$0")/sync_ai_to_all.rb" --target=opencode "$@"
