#!/usr/bin/env ruby
# frozen_string_literal: true

# One-time bootstrap migration script:
# Migrates .claude/ into canonical .ai/ with provider-neutral conventions.

require "fileutils"
require "yaml"

REPO_ROOT = File.expand_path("..", __dir__)
CLAUDE_DIR = File.join(REPO_ROOT, ".claude")
AI_DIR = File.join(REPO_ROOT, ".ai")
OPENCODE_DIR = File.join(REPO_ROOT, ".opencode")
CLAUDE_37_DIR = File.join(REPO_ROOT, ".claude_37signals")
AI_37_DIR = File.join(REPO_ROOT, ".ai_37signals")

TIER_MAP = {
  "haiku" => "fast",
  "sonnet" => "standard",
  "opus" => "powerful"
}.freeze

FileUtils.mkdir_p(File.join(AI_DIR, "settings", "providers"))
FileUtils.mkdir_p(File.join(AI_DIR, "agents"))
FileUtils.mkdir_p(File.join(AI_DIR, "commands"))
FileUtils.mkdir_p(File.join(AI_DIR, "rules"))
FileUtils.mkdir_p(File.join(AI_DIR, "skills"))

# 1. Write Settings
File.write(File.join(AI_DIR, "settings", "model-tiers.yml"), <<~YAML)
# Abstract model tier -> concrete model ID per provider.
# "inherit" means: use the session/project-level default model.
tiers:
  standard:
    claude: "claude-sonnet-4-5"
    opencode: "inherit"
    gemini: "inherit"
    openai: "inherit"
    copilot: "inherit"
    cursor: "inherit"
    antigravity: "inherit"

  fast:
    claude: "claude-haiku-4-5"
    opencode: "inherit"
    gemini: "inherit"
    openai: "inherit"
    copilot: "inherit"
    cursor: "inherit"
    antigravity: "inherit"

  powerful:
    claude: "claude-opus-4-5"
    opencode: "inherit"
    gemini: "inherit"
    openai: "inherit"
    copilot: "inherit"
    cursor: "inherit"
    antigravity: "inherit"
YAML

File.write(File.join(AI_DIR, "settings", "base.yml"), <<~YAML)
# Universal hooks configuration (translated per provider by sync scripts)
hooks:
  session_start:
    - command: "echo \\"Project: $(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)) | Branch: $(git branch --show-current 2>/dev/null || echo 'N/A') | Ruby: $(ruby -v 2>/dev/null | cut -d' ' -f2 || echo 'N/A') | Rails: $(bundle exec rails -v 2>/dev/null | cut -d' ' -f2 || echo 'N/A') | Pending migrations: $(bundle exec rails db:migrate:status 2>/dev/null | grep -c 'down' || echo '0')\\""
      timeout: 15
      description: "Load project context"

  before_tool_bash:
    - check: "destructive_command"
      pattern: "(rm\\\\s+-rf\\\\s+[/~]|DROP\\\\s+TABLE|DROP\\\\s+DATABASE|git\\\\s+push\\\\s+.*(-f|--force)\\\\s+.*(main|master|production)|chmod\\\\s+777)"
      action: "block"
      message: "Blocked: This command is potentially destructive. Please confirm with the user before proceeding."
      timeout: 5

  after_tool_edit_write:
    - condition: "file_ends_with:.rb"
      command: "bundle exec rubocop -a {file}"
      timeout: 30
      description: "Auto-format Ruby with RuboCop"
    - condition: "file_ends_with:.erb"
      command: "bundle exec erblint --autocorrect {file}"
      timeout: 30
      description: "Auto-format ERB"

  session_idle:
    - command: "notify-send \\"AI Agent\\" \\"Response complete\\" 2>/dev/null || osascript -e 'display notification \\"AI agent has finished responding\\" with title \\"AI Agent\\"' 2>/dev/null || true"
      timeout: 5
      description: "Desktop notification on idle"
YAML

File.write(File.join(AI_DIR, "settings", "mcp.yml"), <<~YAML)
servers:
  sentry-monitor:
    type: local
    command:
      - "mcp/sentry_monitor/.venv/bin/python"
      - "-m"
      - "mcp_server.server"
    environment:
      PYTHONPATH: "mcp/sentry_monitor"
    enabled: true
    supported_by: [claude, opencode, gemini, cursor, cline]
YAML

File.write(File.join(AI_DIR, "settings", "claude-agent-extras.yml"), <<~YAML)
defaults:
  tools: [Read, Write, Edit, Glob, Grep, Bash]
  permissionMode: acceptEdits
  memory: project

overrides:
  implementation-agent:
    tools: [Read, Write, Edit, Glob, Grep, Bash, Agent]
    isolation: worktree
    skills:
      - rails-architecture
  controller-agent:
    skills:
      - api-versioning
  job-agent:
    skills:
      - solid-queue-setup
  turbo-agent:
    skills:
      - action-cable-patterns
  lint-agent:
    effort: low
YAML

# Provider definition files
providers = {
  "claude.yml" => {
    "name" => "Claude Code",
    "type" => "file_based",
    "reads" => ["CLAUDE.md", ".claude/"],
    "output" => { "mode" => "claude_native", "target" => ".claude/" },
    "mcp_supported" => true
  },
  "opencode.yml" => {
    "name" => "opencode",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".opencode/", "opencode.json"],
    "output" => { "mode" => "opencode_native", "target" => ".opencode/" },
    "mcp_supported" => true
  },
  "gemini.yml" => {
    "name" => "Gemini CLI",
    "type" => "file_based",
    "reads" => ["GEMINI.md", "AGENTS.md", ".gemini/"],
    "output" => { "mode" => "rules_directory", "target" => ".gemini/rules/" },
    "mcp_supported" => true
  },
  "antigravity.yml" => {
    "name" => "Antigravity",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".agents/"],
    "output" => { "mode" => "agents_md_passthrough" },
    "mcp_supported" => true
  },
  "cursor.yml" => {
    "name" => "Cursor",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".cursor/rules/*.mdc"],
    "output" => { "mode" => "mdc_directory", "target" => ".cursor/rules/" },
    "mcp_supported" => true
  },
  "windsurf.yml" => {
    "name" => "Windsurf",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".windsurfrules"],
    "output" => { "mode" => "single_rules_file", "target" => ".windsurfrules" },
    "mcp_supported" => false
  },
  "cline.yml" => {
    "name" => "Cline",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".clinerules/"],
    "output" => { "mode" => "rules_directory", "target" => ".clinerules/" },
    "mcp_supported" => true
  },
  "continue.yml" => {
    "name" => "Continue.dev",
    "type" => "file_based",
    "reads" => [".continue/rules/"],
    "output" => { "mode" => "rules_directory", "target" => ".continue/rules/" },
    "mcp_supported" => true
  },
  "aider.yml" => {
    "name" => "Aider",
    "type" => "file_based",
    "reads" => ["CONVENTIONS.md", "AGENTS.md", ".aider.conf.yml"],
    "output" => { "mode" => "single_rules_file", "target" => "CONVENTIONS.md" },
    "mcp_supported" => false
  },
  "copilot.yml" => {
    "name" => "GitHub Copilot",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".github/copilot-instructions.md", ".github/instructions/"],
    "output" => { "mode" => "bridge_files", "target" => ".github/instructions/" },
    "mcp_supported" => false
  },
  "codex.yml" => {
    "name" => "OpenAI Codex CLI",
    "type" => "file_based",
    "reads" => ["AGENTS.md", ".agents/skills/"],
    "output" => { "mode" => "agents_md_passthrough" },
    "mcp_supported" => false
  },
  "mimo.yml" => {
    "name" => "MiMo Code",
    "type" => "file_based",
    "reads" => ["AGENTS.md", "CLAUDE.md"],
    "output" => { "mode" => "agents_md_passthrough" },
    "mcp_supported" => true
  },
  "kimi.yml" => {
    "name" => "Kimi Code",
    "type" => "file_based",
    "reads" => ["AGENTS.md", "CLAUDE.md"],
    "output" => { "mode" => "agents_md_passthrough" },
    "mcp_supported" => true
  },
  "muse.yml" => {
    "name" => "Muse Code",
    "type" => "file_based",
    "reads" => ["AGENTS.md"],
    "output" => { "mode" => "agents_md_passthrough" },
    "mcp_supported" => false
  }
}

providers.each do |filename, config|
  File.write(File.join(AI_DIR, "settings", "providers", filename), config.to_yaml)
end

# Helper to parse frontmatter
def split_fm(path)
  lines = File.readlines(path)
  return [nil, lines.join] unless lines.first == "---\n"
  closing = lines[1..].index("---\n")
  return [nil, lines.join] if closing.nil?
  [lines[1, closing], lines[(closing + 2)..].to_a.join]
end

# 2. Migrate Agents
Dir.glob(File.join(CLAUDE_DIR, "agents", "*.md")).sort.each do |file|
  fm, body = split_fm(file)
  next if fm.nil?

  name = fm.find { |l| l.start_with?("name:") }&.sub(/^name:\s*/, "")&.strip
  desc = fm.find { |l| l.start_with?("description:") }&.sub(/^description:\s*/, "")&.strip
  model_raw = fm.find { |l| l.start_with?("model:") }&.sub(/^model:\s*/, "")&.strip
  tier = TIER_MAP[model_raw] || "standard"
  max_turns = fm.find { |l| l.start_with?("maxTurns:") }&.sub(/^maxTurns:\s*/, "")&.strip || "30"

  # Clean up any provider-specific tooling text in agent body
  clean_body = body.gsub("use the `runSubagent` tool to delegate", "delegate")
                   .gsub("use the runSubagent tool to delegate", "delegate")

  new_fm = <<~FM
  ---
  name: #{name}
  description: >-
    #{desc}
  model_tier: #{tier}
  maxTurns: #{max_turns}
  ---
  FM

  File.write(File.join(AI_DIR, "agents", "#{name}.md"), "#{new_fm}\n#{clean_body.strip}\n")
  puts "Migrated agent: #{name} (tier: #{tier})"
end

# Copy agent references
if Dir.exist?(File.join(CLAUDE_DIR, "agents", "references"))
  FileUtils.cp_r(File.join(CLAUDE_DIR, "agents", "references"), File.join(AI_DIR, "agents", "references"))
end

# 3. Migrate Commands
Dir.glob(File.join(CLAUDE_DIR, "commands", "**", "*.md")).sort.each do |file|
  rel = file.delete_prefix(File.join(CLAUDE_DIR, "commands") + File::SEPARATOR)
  target_file = File.join(AI_DIR, "commands", rel)
  FileUtils.mkdir_p(File.dirname(target_file))

  content = File.read(file)
  # Neutralize command language
  content = content.gsub("prompt engineering specialist for Claude Code", "prompt engineering specialist for AI coding assistants")
                   .gsub("directly from Claude Code after verifying a fix", "directly from the AI assistant after verifying a fix")
                   .gsub("actionable Claude Code prompts", "actionable AI prompts")

  File.write(target_file, content)
  puts "Migrated command: #{rel}"
end

# 4. Migrate Rules
Dir.glob(File.join(CLAUDE_DIR, "rules", "*.md")).sort.each do |file|
  name = File.basename(file)
  FileUtils.cp(file, File.join(AI_DIR, "rules", name))
  puts "Migrated rule: #{name}"
end

# 5. Migrate Skills
Dir.glob(File.join(CLAUDE_DIR, "skills", "*")).sort.each do |dir|
  next unless File.directory?(dir)
  name = File.basename(dir)
  target = File.join(AI_DIR, "skills", name)
  FileUtils.rm_rf(target)
  FileUtils.cp_r(dir, target)
  puts "Migrated skill: #{name}"
end

# 6. Migrate 37signals pack if present
if Dir.exist?(CLAUDE_37_DIR)
  FileUtils.mkdir_p(AI_37_DIR)
  FileUtils.cp_r(File.join(CLAUDE_37_DIR, "."), AI_37_DIR)
  puts "Migrated .claude_37signals to .ai_37signals"
end

puts "\nSuccessfully bootstrapped .ai/ canonical directory!"
