#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ruby "${SCRIPT_DIR}/sync_claude_to_opencode.rb"
