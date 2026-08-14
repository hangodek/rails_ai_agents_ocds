#!/usr/bin/env ruby
# frozen_string_literal: true

# Master AI Sync Script:
# Syncs canonical .ai/ configuration to all supported AI platforms and tools:
# - Claude Code (.claude/, CLAUDE.md)
# - opencode (.opencode/, opencode.json, .agents/skills/)
# - Gemini CLI & Antigravity (GEMINI.md, .gemini/, .agents/)
# - Cursor (.cursor/rules/*.mdc)
# - Windsurf (.windsurfrules)
# - Cline (.clinerules/)
# - Continue.dev (.continue/rules/)
# - Aider (CONVENTIONS.md, .aider.conf.yml)
# - GitHub Copilot (.github/instructions/, .github/copilot-instructions.md)
# - Universal Context Bundle (AI_CONTEXT.md) for web chat / API AIs

require "fileutils"
require "yaml"
require "json"

REPO_ROOT = File.expand_path("..", __dir__)
AI_DIR = File.join(REPO_ROOT, ".ai")

# Load settings
TIERS = YAML.load_file(File.join(AI_DIR, "settings", "model-tiers.yml"))
CLAUDE_EXTRAS = YAML.load_file(File.join(AI_DIR, "settings", "claude-agent-extras.yml")) rescue {}
MCP_CONFIG = YAML.load_file(File.join(AI_DIR, "settings", "mcp.yml")) rescue {}

TARGET_ARG = ARGV.find { |a| a.start_with?("--target=") }&.sub(/^--target=/, "")&.downcase || "all"

def target_enabled?(name)
  TARGET_ARG == "all" || TARGET_ARG == name.downcase
end

# --- Helpers ---

def split_frontmatter(path)
  lines = File.readlines(path)
  return [nil, lines.join] unless lines.first == "---\n"
  closing = lines[1..].index("---\n")
  return [nil, lines.join] if closing.nil?
  [lines[1, closing], lines[(closing + 2)..].to_a.join]
end

def parse_frontmatter_yaml(lines)
  return {} if lines.nil? || lines.empty?
  YAML.safe_load(lines.join) || {}
rescue StandardError
  {}
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def clean_and_recreate_dir(path)
  FileUtils.rm_rf(path)
  FileUtils.mkdir_p(path)
end

def resolved_model(tier, provider)
  TIERS.dig("tiers", tier, provider) || "inherit"
end

# --- 1. Claude Code (.claude/) ---

def sync_claude
  puts "Syncing Claude Code (.claude/)..."
  target_dir = File.join(REPO_ROOT, ".claude")
  clean_and_recreate_dir(File.join(target_dir, "agents"))
  clean_and_recreate_dir(File.join(target_dir, "commands"))
  clean_and_recreate_dir(File.join(target_dir, "rules"))
  clean_and_recreate_dir(File.join(target_dir, "skills"))

  defaults = CLAUDE_EXTRAS["defaults"] || {
    "tools" => %w[Read Write Edit Glob Grep Bash],
    "permissionMode" => "acceptEdits",
    "memory" => "project"
  }
  overrides = CLAUDE_EXTRAS["overrides"] || {}

  agent_count = 0
  # Agents
  Dir.glob(File.join(AI_DIR, "agents", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    fm_lines, body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)

    tier = data["model_tier"] || "standard"
    model = resolved_model(tier, "claude")
    model = "sonnet" if model == "inherit" || model.nil?
    model_name = case model
                 when /haiku/ then "haiku"
                 when /opus/ then "opus"
                 when /sonnet/ then "sonnet"
                 else model
                 end

    extra = overrides[name] || {}
    tools = extra["tools"] || defaults["tools"]
    perm = extra["permissionMode"] || defaults["permissionMode"]
    mem = extra["memory"] || defaults["memory"]
    max_turns = data["maxTurns"] || 30

    fm_out = [
      "name: #{name}",
      "description: >-",
      "  #{data['description'] || ''}".rstrip,
      "tools: [#{tools.join(', ')}]",
      "model: #{model_name}",
      "maxTurns: #{max_turns}",
      "permissionMode: #{perm}",
      "memory: #{mem}"
    ]
    fm_out << "isolation: #{extra['isolation']}" if extra["isolation"]
    fm_out << "effort: #{extra['effort']}" if extra["effort"]
    if extra["skills"]
      fm_out << "skills:"
      extra["skills"].each { |s| fm_out << "  - #{s}" }
    end

    out_content = "---\n#{fm_out.join("\n")}\n---\n\n#{body.strip}\n"
    write_file(File.join(target_dir, "agents", "#{name}.md"), out_content)
    agent_count += 1
  end

  # Copy references
  if Dir.exist?(File.join(AI_DIR, "agents", "references"))
    FileUtils.rm_rf(File.join(target_dir, "agents", "references"))
    FileUtils.cp_r(File.join(AI_DIR, "agents", "references"), File.join(target_dir, "agents", "references"))
  end

  # Copy commands
  FileUtils.rm_rf(File.join(target_dir, "commands"))
  FileUtils.cp_r(File.join(AI_DIR, "commands"), File.join(target_dir, "commands"))

  # Copy rules
  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    FileUtils.cp(file, File.join(target_dir, "rules", File.basename(file)))
    rule_count += 1
  end

  # Copy skills
  FileUtils.rm_rf(File.join(target_dir, "skills"))
  FileUtils.cp_r(File.join(AI_DIR, "skills"), File.join(target_dir, "skills"))

  # Generate settings.json
  settings_json = {
    "$schema" => "https://json.schemastore.org/claude-code-settings.json",
    "env" => {
      "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" => "1"
    },
    "hooks" => {
      "SessionStart" => [
        {
          "hooks" => [
            {
              "type" => "command",
              "command" => "echo \"Project: $(basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)) | Branch: $(git branch --show-current 2>/dev/null || echo 'N/A') | Ruby: $(ruby -v 2>/dev/null | cut -d' ' -f2 || echo 'N/A') | Rails: $(bundle exec rails -v 2>/dev/null | cut -d' ' -f2 || echo 'N/A') | Pending migrations: $(bundle exec rails db:migrate:status 2>/dev/null | grep -c 'down' || echo '0')\"",
              "timeout" => 15,
              "statusMessage" => "Loading project context..."
            }
          ]
        }
      ],
      "PostToolUse" => [
        {
          "matcher" => "Edit|Write",
          "hooks" => [
            {
              "type" => "command",
              "command" => "FILE=$(cat | jq -r '.tool_input.file_path // empty') && [ -n \"$FILE\" ] && [[ \"$FILE\" == *.rb ]] && bundle exec rubocop -a \"$FILE\" > /dev/null 2>&1 || true",
              "timeout" => 30,
              "statusMessage" => "Auto-formatting with RuboCop..."
            },
            {
              "type" => "command",
              "command" => "FILE=$(cat | jq -r '.tool_input.file_path // empty') && [ -n \"$FILE\" ] && [[ \"$FILE\" == *.erb ]] && bundle exec erblint --autocorrect \"$FILE\" > /dev/null 2>&1 || true",
              "timeout" => 30,
              "statusMessage" => "Auto-formatting ERB..."
            }
          ]
        }
      ],
      "PreToolUse" => [
        {
          "matcher" => "Bash",
          "hooks" => [
            {
              "type" => "command",
              "command" => "CMD=$(cat | jq -r '.tool_input.command // empty') && if echo \"$CMD\" | grep -qiE '(rm\\s+-rf\\s+[/~]|DROP\\s+TABLE|DROP\\s+DATABASE|git\\s+push\\s+.*(-f|--force)\\s+.*(main|master|production)|chmod\\s+777)'; then echo 'Blocked: This command is potentially destructive. Please confirm with the user before proceeding.' >&2; exit 2; fi",
              "timeout" => 5,
              "statusMessage" => "Checking command safety..."
            }
          ]
        }
      ],
      "TaskCompleted" => [
        {
          "hooks" => [
            {
              "type" => "command",
              "command" => "TASK=$(cat | jq -r '.task.description // empty') && if echo \"$TASK\" | grep -qiE '(implement|create|add|build|write|fix|refactor|update|migrate|change|move|extract)'; then echo '{\"systemMessage\": \"Before marking complete: verify tests pass (bundle exec rspec) and linting is clean (bundle exec rubocop). If you have not run these checks, do so now.\"}'; fi",
              "timeout" => 5,
              "statusMessage" => "Checking task completion quality..."
            }
          ]
        }
      ],
      "Stop" => [
        {
          "hooks" => [
            {
              "type" => "command",
              "command" => "osascript -e 'display notification \"AI agent has finished responding\" with title \"Claude Code\"' 2>/dev/null || true",
              "timeout" => 5
            }
          ]
        }
      ]
    }
  }
  File.write(File.join(target_dir, "settings.json"), JSON.pretty_generate(settings_json) + "\n")

  # CLAUDE.md entry point
  File.write(File.join(REPO_ROOT, "CLAUDE.md"), "@AGENTS.md\n")
  puts "  Synced #{agent_count} agents, #{rule_count} rules, commands, skills, settings.json, CLAUDE.md"
end

# --- 2. opencode (.opencode/) ---

def adapt_command_for_opencode(body)
  body.gsub(
    "Use the Agent tool with these parameters:\n" \
    "   - `isolation: \"worktree\"` — creates an isolated git worktree\n" \
    "   - `run_in_background: true` — runs asynchronously\n" \
    "   - `description: \"Fix Sentry {short_id}\"`",
    "Use the `task` tool routed to the `implementation-agent` (or `general`), " \
    "in background/parallel mode if available, with `description: \"Fix Sentry {short_id}\"`"
  ).gsub(
    "Update the status of a Sentry issue directly from Claude Code after verifying a fix.",
    "Update the status of a Sentry issue directly from the AI assistant after verifying a fix."
  )
end

def sync_opencode
  puts "Syncing opencode (.opencode/)..."
  target_dir = File.join(REPO_ROOT, ".opencode")
  manifest_path = File.join(target_dir, ".ai-sync-manifest")
  skills_target_dir = File.join(REPO_ROOT, ".agents", "skills")

  clean_and_recreate_dir(File.join(target_dir, "agents"))
  clean_and_recreate_dir(File.join(target_dir, "commands"))
  clean_and_recreate_dir(File.join(target_dir, "rules"))
  FileUtils.mkdir_p(skills_target_dir)

  manifest_entries = []

  # Agents
  Dir.glob(File.join(AI_DIR, "agents", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    fm_lines, body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)

    adapted_body = body.gsub(/\]\(references\//, "](.opencode/agents/references/")
    fm_out = [
      "name: #{name}",
      "description: >-",
      "  #{data['description'] || ''}".rstrip,
      "mode: subagent",
      "permission:",
      "  edit: allow"
    ]
    out_content = "---\n#{fm_out.join("\n")}\n---\n\n#{adapted_body.strip}\n"
    write_file(File.join(target_dir, "agents", "#{name}.md"), out_content)
    manifest_entries << "agent:#{name}"
  end

  # References
  if Dir.exist?(File.join(AI_DIR, "agents", "references"))
    FileUtils.rm_rf(File.join(target_dir, "agents", "references"))
    FileUtils.cp_r(File.join(AI_DIR, "agents", "references"), File.join(target_dir, "agents", "references"))
  end

  # Commands
  Dir.glob(File.join(AI_DIR, "commands", "**", "*.md")).sort.each do |file|
    rel = file.delete_prefix(File.join(AI_DIR, "commands") + File::SEPARATOR)
    fm_lines, body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)

    fm_out = []
    if data["description"]
      fm_out << "description: >-"
      fm_out << "  #{data['description']}"
    end
    fm_str = fm_out.empty? ? "" : "---\n#{fm_out.join("\n")}\n---\n\n"
    out_content = "#{fm_str}#{adapt_command_for_opencode(body).strip}\n"
    write_file(File.join(target_dir, "commands", rel), out_content)
    manifest_entries << "command:#{rel.delete_suffix('.md')}"
  end

  # Rules (strip frontmatter)
  rules_for_json = []
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm_lines, body = split_frontmatter(file)
    write_file(File.join(target_dir, "rules", "#{name}.md"), body.strip + "\n")
    manifest_entries << "rule:#{name}"
    rules_for_json << ".opencode/rules/#{name}.md"
  end

  # Skills -> .agents/skills/
  Dir.glob(File.join(AI_DIR, "skills", "*")).sort.each do |dir|
    next unless File.directory?(dir)
    name = File.basename(dir)
    dest = File.join(skills_target_dir, name)
    FileUtils.rm_rf(dest)
    FileUtils.cp_r(dir, dest)
    manifest_entries << "skill:#{name}"
  end

  # Write manifest and remove old claude manifest
  File.write(manifest_path, manifest_entries.sort.join("\n") + "\n")
  FileUtils.rm_f(File.join(target_dir, ".claude-sync-manifest"))
  FileUtils.rm_f(File.join(skills_target_dir, ".claude-sync-manifest"))
  File.write(File.join(skills_target_dir, ".ai-sync-manifest"), manifest_entries.select { |e| e.start_with?("skill:") }.join("\n") + "\n")

  # Regenerate opencode.json
  opencode_json = {
    "$schema" => "https://opencode.ai/config.json",
    "model" => "opencode/deepseek-v4-flash-free",
    "small_model" => "opencode/deepseek-v4-flash-free",
    "instructions" => ["AGENTS.md"] + rules_for_json,
    "mcp" => {
      "sentry-monitor" => {
        "type" => "local",
        "command" => [
          "mcp/sentry_monitor/.venv/bin/python",
          "-m",
          "mcp_server.server"
        ],
        "environment" => {
          "PYTHONPATH" => "mcp/sentry_monitor"
        },
        "enabled" => true
      }
    }
  }
  File.write(File.join(REPO_ROOT, "opencode.json"), JSON.pretty_generate(opencode_json) + "\n")
  puts "  Synced #{manifest_entries.size} items and updated opencode.json with #{rules_for_json.size} rules"
end

# --- 3. Gemini CLI & Antigravity (GEMINI.md, .gemini/, .agents/) ---

def sync_gemini_and_antigravity
  puts "Syncing Gemini & Antigravity (.gemini/, .agents/, GEMINI.md)..."
  gemini_dir = File.join(REPO_ROOT, ".gemini")
  agents_dir = File.join(REPO_ROOT, ".agents")

  clean_and_recreate_dir(File.join(gemini_dir, "rules"))
  clean_and_recreate_dir(File.join(gemini_dir, "agents"))
  clean_and_recreate_dir(File.join(agents_dir, "rules"))

  # GEMINI.md pointer
  File.write(File.join(REPO_ROOT, "GEMINI.md"), "@AGENTS.md\n")

  rule_count = 0
  # Rules
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm, body = split_frontmatter(file)
    content = body.strip + "\n"
    File.write(File.join(gemini_dir, "rules", "#{name}.md"), content)
    File.write(File.join(agents_dir, "rules", "#{name}.md"), content)
    rule_count += 1
  end

  agent_count = 0
  # Agents
  Dir.glob(File.join(AI_DIR, "agents", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    fm_lines, body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)

    adapted_body = body.gsub(/\]\(references\//, "](.gemini/agents/references/")
    fm_out = [
      "name: #{name}",
      "description: >-",
      "  #{data['description'] || ''}".rstrip
    ]
    out = "---\n#{fm_out.join("\n")}\n---\n\n#{adapted_body.strip}\n"
    File.write(File.join(gemini_dir, "agents", "#{name}.md"), out)
    agent_count += 1
  end

  # References
  if Dir.exist?(File.join(AI_DIR, "agents", "references"))
    clean_and_recreate_dir(File.join(gemini_dir, "agents", "references"))
    FileUtils.cp_r(File.join(AI_DIR, "agents", "references", "."), File.join(gemini_dir, "agents", "references"))
    clean_and_recreate_dir(File.join(agents_dir, "references"))
    FileUtils.cp_r(File.join(AI_DIR, "agents", "references", "."), File.join(agents_dir, "references"))
  end
  puts "  Synced #{agent_count} agents and #{rule_count} rules for .gemini/ and .agents/"
end

# --- 4. Cursor (.cursor/rules/*.mdc) ---

def sync_cursor
  puts "Syncing Cursor (.cursor/rules/*.mdc)..."
  cursor_dir = File.join(REPO_ROOT, ".cursor", "rules")
  clean_and_recreate_dir(cursor_dir)

  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    fm_lines, body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)

    globs = data["paths"] || ["**/*"]
    always_apply = ["principles", "caveman", "cli", "cli-tools"].include?(name)

    mdc_fm = [
      "description: #{name.capitalize} conventions for Rails",
      "globs: #{globs.inspect}",
      "alwaysApply: #{always_apply}"
    ]
    content = "---\n#{mdc_fm.join("\n")}\n---\n\n<!-- Generated from .ai/rules/#{name}.md -->\n\n#{body.strip}\n"
    File.write(File.join(cursor_dir, "#{name}.mdc"), content)
    rule_count += 1
  end
  puts "  Synced #{rule_count} .mdc rule files in .cursor/rules/"
end

# --- 5. Windsurf (.windsurfrules) ---

def sync_windsurf
  puts "Syncing Windsurf (.windsurfrules)..."
  rules_content = [
    "# Rails Development Conventions and Rules\n",
    "<!-- Generated by scripts/sync_ai_to_all.rb from .ai/rules/ -->\n"
  ]

  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm, body = split_frontmatter(file)
    rules_content << "## #{name.capitalize} Rules\n\n#{body.strip}\n\n---\n"
    rule_count += 1
  end

  File.write(File.join(REPO_ROOT, ".windsurfrules"), rules_content.join("\n"))
  puts "  Generated .windsurfrules (#{rule_count} rules)"
end

# --- 6. Cline (.clinerules/) ---

def sync_cline
  puts "Syncing Cline (.clinerules/)..."
  cline_dir = File.join(REPO_ROOT, ".clinerules")
  clean_and_recreate_dir(cline_dir)

  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm, body = split_frontmatter(file)
    content = "<!-- Generated from .ai/rules/#{name}.md -->\n\n#{body.strip}\n"
    File.write(File.join(cline_dir, "#{name}.md"), content)
    rule_count += 1
  end
  puts "  Generated #{rule_count} rules in .clinerules/"
end

# --- 7. Continue.dev (.continue/rules/) ---

def sync_continue
  puts "Syncing Continue.dev (.continue/rules/)..."
  continue_dir = File.join(REPO_ROOT, ".continue", "rules")
  clean_and_recreate_dir(continue_dir)

  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm, body = split_frontmatter(file)
    content = "<!-- Generated from .ai/rules/#{name}.md -->\n\n#{body.strip}\n"
    File.write(File.join(continue_dir, "#{name}.md"), content)
    rule_count += 1
  end
  puts "  Generated #{rule_count} rules in .continue/rules/"
end

# --- 8. Aider (CONVENTIONS.md, .aider.conf.yml) ---

def sync_aider
  puts "Syncing Aider (CONVENTIONS.md, .aider.conf.yml)..."
  conventions_content = [
    "# Rails AI Coding Conventions\n",
    "<!-- Generated by scripts/sync_ai_to_all.rb from .ai/rules/ -->\n"
  ]

  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm, body = split_frontmatter(file)
    conventions_content << "## #{name.capitalize} Rules\n\n#{body.strip}\n\n---\n"
    rule_count += 1
  end

  File.write(File.join(REPO_ROOT, "CONVENTIONS.md"), conventions_content.join("\n"))

  aider_conf = <<~YAML
    # Aider configuration
    read: CONVENTIONS.md
    auto-commits: false
  YAML
  File.write(File.join(REPO_ROOT, ".aider.conf.yml"), aider_conf)
  puts "  Generated CONVENTIONS.md (#{rule_count} rules) and .aider.conf.yml"
end

# --- 9. GitHub Copilot (.github/instructions/) ---

def sync_copilot
  puts "Syncing GitHub Copilot..."
  instructions_dir = File.join(REPO_ROOT, ".github", "instructions", "rules")
  clean_and_recreate_dir(instructions_dir)

  rule_count = 0
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    fm_lines, _body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)
    paths = data["paths"] || ["**"]
    apply_to = paths.join(",")

    content = <<~MD
      ---
      applyTo: "#{apply_to}"
      ---

      <!-- Generated by scripts/sync_ai_to_all.rb -->
      <!-- Canonical source: .ai/rules/#{name}.md -->

      # Copilot Bridge: #{name}

      Read and apply `.ai/rules/#{name}.md` before editing files matching this scope.
    MD
    File.write(File.join(instructions_dir, "#{name}.instructions.md"), content)
    rule_count += 1
  end

  # Update .github/copilot-instructions.md
  copilot_main = <<~MD
    # GitHub Copilot Instructions

    Use these instructions as a compatibility bridge so GitHub Copilot adheres to this repo's universal AI conventions.

    ## Canonical Sources

    - Architecture and workflow conventions: `AGENTS.md`
    - Canonical agent instructions and rules: `.ai/`
    - Copilot-friendly mirrored skills: `.agents/skills/`

    ## Rule Loading Strategy

    - Path-scoped Copilot bridge files live in `.github/instructions/rules/`.
    - Each bridge points to a canonical `.ai/rules/*.md` file.
    - Follow the canonical `.ai/rules/*.md` content.

    ## Maintenance

    Run `ruby scripts/sync_ai_to_all.rb` after adding, removing, or renaming a rule or skill.
  MD
  File.write(File.join(REPO_ROOT, ".github", "copilot-instructions.md"), copilot_main)
  puts "  Generated #{rule_count} Copilot bridge files and updated copilot-instructions.md"
end

# --- 10. Universal Context Bundle (AI_CONTEXT.md) ---

def generate_context_bundle
  puts "Generating Universal Context Bundle (AI_CONTEXT.md)..."
  bundle = []

  bundle << "# Universal Rails AI Agent Context Bundle"
  bundle << "> **How to use:** Paste this file's content into any chat AI (Kimi, ChatGPT, Ling, Muse AI, Claude web, Gemini web, or API system prompt) to give it full project awareness."
  bundle << "> **Source of truth:** `.ai/` | Generated automatically by `scripts/sync_ai_to_all.rb`.\n"

  # 1. Project Overview (extract developer-facing sections of AGENTS.md before internal AI Tooling table)
  if File.exist?(File.join(REPO_ROOT, "AGENTS.md"))
    agents_md = File.read(File.join(REPO_ROOT, "AGENTS.md"))
    # Extract only tech stack, architecture, commands, workflow, conventions (stop before ## AI Tooling)
    dev_content = agents_md.split(/^## AI Tooling/)[0].strip
    bundle << "## 1. Project Overview & Architecture\n"
    bundle << dev_content
    bundle << "\n---\n"
  end

  # 2. Specialist Agents List
  bundle << "## 2. Available Specialist Agents\n"
  bundle << "When prompting, you can ask the AI to assume any of these specialist roles:\n"
  Dir.glob(File.join(AI_DIR, "agents", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    fm_lines, _body = split_frontmatter(file)
    data = parse_frontmatter_yaml(fm_lines)
    tier = data["model_tier"] || "standard"
    desc = data["description"]&.gsub("\n", " ")&.strip
    bundle << "- **`@#{name}`** (Tier: `#{tier}`): #{desc}"
  end
  bundle << "\n---\n"

  # 3. All Rules and Conventions Inlined
  bundle << "## 3. Project Coding Rules & Standards\n"
  Dir.glob(File.join(AI_DIR, "rules", "*.md")).sort.each do |file|
    name = File.basename(file, ".md")
    _fm_lines, body = split_frontmatter(file)
    bundle << "### #{name.capitalize} Rules\n"
    bundle << body.strip
    bundle << "\n"
  end

  File.write(File.join(REPO_ROOT, "AI_CONTEXT.md"), bundle.join("\n\n") + "\n")
  puts "  Generated AI_CONTEXT.md (#{File.readlines(File.join(REPO_ROOT, 'AI_CONTEXT.md')).size} lines)"
end

# --- Main Dispatcher ---

puts "=================================================="
puts "  Rails AI Agents: Universal Multi-Provider Sync"
puts "  Target: #{TARGET_ARG.upcase}"
puts "=================================================="

sync_claude                  if target_enabled?("claude")
sync_opencode                if target_enabled?("opencode")
sync_gemini_and_antigravity  if target_enabled?("gemini") || target_enabled?("antigravity")
sync_cursor                  if target_enabled?("cursor")
sync_windsurf                if target_enabled?("windsurf")
sync_cline                   if target_enabled?("cline")
sync_continue                if target_enabled?("continue")
sync_aider                   if target_enabled?("aider")
sync_copilot                 if target_enabled?("copilot")
generate_context_bundle      if target_enabled?("bundle") || TARGET_ARG == "all"

puts "=================================================="
puts "  All targets successfully synced!"
puts "=================================================="
