#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Rails AI Agents — Universal Installer
# One-command setup for any Rails project.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/hangodek/rails_ai_agents_ocds/main/install.sh | bash
# ==============================================================================

REPO="hangodek/rails_ai_agents_ocds"
BRANCH="main"

echo "=================================================="
echo "  Installing Universal Rails AI Agents"
echo "  Source: github.com/${REPO} (${BRANCH})"
echo "=================================================="

# Check if Ruby is installed
if ! command -v ruby >/dev/null 2>&1; then
  echo "Error: Ruby is required to run the AI sync engine. Please install Ruby first." >&2
  exit 1
fi

# Check if Git is installed
if ! command -v git >/dev/null 2>&1; then
  echo "Error: Git is required to download agent definitions. Please install Git first." >&2
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

echo "1. Downloading canonical AI agent definitions..."
git clone --depth=1 --branch="${BRANCH}" "https://github.com/${REPO}.git" "${TMP_DIR}" 2>/dev/null || \
git clone --depth=1 "https://github.com/${REPO}.git" "${TMP_DIR}"

echo "2. Installing into current directory..."
cp -r "${TMP_DIR}/.ai" .
mkdir -p scripts
cp "${TMP_DIR}/scripts/sync_ai_to_all.rb" scripts/
cp "${TMP_DIR}/scripts/sync_all.sh" scripts/
chmod +x scripts/sync_ai_to_all.rb scripts/sync_all.sh
cp "${TMP_DIR}/AGENTS.md" AGENTS.md
cp "${TMP_DIR}/GEMINI.md" GEMINI.md
echo "@AGENTS.md" > CLAUDE.md

echo "3. Generating AI tool targets (Cursor, Claude, Windsurf, opencode, etc.)..."
ruby scripts/sync_ai_to_all.rb

echo "4. Configuring .gitignore..."
if [ -f .gitignore ]; then
  if ! grep -q "AI tool generated configs" .gitignore 2>/dev/null; then
    cat >> .gitignore << 'GITIGNORE'

# AI tool generated configs — run: scripts/sync_all.sh to regenerate
.cursor/rules/
.windsurfrules
.clinerules/
.continue/
.gemini/
.agents/rules/
CONVENTIONS.md
AI_CONTEXT.md
.aider.conf.yml
.github/instructions/rules/
GITIGNORE
    echo "  Added generated AI config paths to .gitignore"
  fi
fi

echo ""
echo "=================================================="
echo "  Universal Rails AI Agents Successfully Installed!"
echo "=================================================="
echo "  • Source of truth:   .ai/ (edit rules & agents here)"
echo "  • Sync changes:      scripts/sync_all.sh"
echo "  • Open standards:    AGENTS.md & GEMINI.md"
echo "  • For chat AIs:      paste AI_CONTEXT.md into ChatGPT/Kimi/Ling"
echo "=================================================="
