#!/usr/bin/env ruby
# frozen_string_literal: true

# Syncs Claude Code configuration (.claude/) to opencode (.opencode/ and .agents/).
#
# - agents:   .claude/agents/<name>.md  -> .opencode/agents/<name>.md
#             (Claude frontmatter keys are dropped; mode/permission added)
# - commands: .claude/commands/**/*.md  -> .opencode/commands/**/*.md
#             (only `description` is kept from the frontmatter)
# - rules:    .claude/rules/<name>.md   -> .opencode/rules/<name>.md
#             (frontmatter stripped; loaded via opencode.json "instructions")
# - skills:   .claude/skills/<name>/    -> .agents/skills/<name>/
# - references: .claude/agents/references/ -> .opencode/agents/references/
#             (relative `references/...` links in agent bodies are rewritten
#              to project-root-relative paths so opencode can read them)

require "fileutils"

REPO_ROOT = File.expand_path("..", __dir__)
CLAUDE_DIR = File.join(REPO_ROOT, ".claude")
OPENCODE_DIR = File.join(REPO_ROOT, ".opencode")
SKILLS_TARGET_DIR = File.join(REPO_ROOT, ".agents", "skills")
MANIFEST_PATH = File.join(OPENCODE_DIR, ".claude-sync-manifest")

AGENT_FM_ADD = ["mode: subagent", "permission:", "  edit: allow"].freeze

# --- helpers ---------------------------------------------------------------

def split_frontmatter(path)
  lines = File.readlines(path)
  return [nil, lines.join] unless lines.first == "---\n"

  closing = lines[1..].index("---\n")
  return [nil, lines.join] if closing.nil?

  [lines[1, closing], lines[(closing + 2)..].to_a.join]
end

def write_file(path, content)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

def write_with_frontmatter(path, fm_lines, body)
  lines = fm_lines.map { |l| l.end_with?("\n") ? l : "#{l}\n" }
  write_file(path, "---\n#{lines.join}---\n#{body}")
end

def prune(section, current, target_dir)
  previous = File.readlines(MANIFEST_PATH).map(&:chomp) if File.exist?(MANIFEST_PATH)
  previous = previous.to_a.select { |l| l.start_with?("#{section}:") }
  previous.each do |line|
    name = line.split(":", 2)[1]
    next if current.include?(name)

    FileUtils.rm_rf(File.join(target_dir, name), secure: true)
  end
end

# --- agents ----------------------------------------------------------------

def sync_agents
  source = File.join(CLAUDE_DIR, "agents")
  target = File.join(OPENCODE_DIR, "agents")
  @agents = []

  Dir.glob(File.join(source, "*.md")).sort.each do |file|
    fm, body = split_frontmatter(file)
    next if fm.nil?

    name = fm.find { |l| l.start_with?("name:") }&.sub(/^name:\s*/, "")&.strip
    next if name.nil? || name.empty?

    description = fm.find { |l| l.start_with?("description:") }&.sub(/^description:\s*/, "")&.strip
    body = body.gsub(/\]\(references\//, "](.opencode/agents/references/")
    fm_lines = ["name: #{name}", "description: >-", "  #{description}", *AGENT_FM_ADD]
    write_with_frontmatter(File.join(target, "#{name}.md"), fm_lines, body)
    @agents << name
    puts "Agent: #{name}"
  end

  refs_source = File.join(source, "references")
  refs_target = File.join(target, "references")
  FileUtils.rm_rf(refs_target, secure: true)
  FileUtils.cp_r(refs_source, refs_target) if Dir.exist?(refs_source)

  prune("agent", @agents, target)
end

# --- commands --------------------------------------------------------------

# opencode-specific adaptations applied to command bodies after conversion.
# Keeps `.claude/` canonical while the mirror stays accurate for opencode.
def adapt_command_body(body)
  body = body.gsub(
    "Use the Agent tool with these parameters:\n" \
    "   - `isolation: \"worktree\"` — creates an isolated git worktree\n" \
    "   - `run_in_background: true` — runs asynchronously\n" \
    "   - `description: \"Fix Sentry {short_id}\"`",
    "Use the `task` tool routed to the `implementation-agent` (or `general`), " \
    "in background/parallel mode if available, with `description: \"Fix Sentry {short_id}\"`"
  )
  body.gsub(
    "Update the status of a Sentry issue directly from Claude Code after verifying a fix.",
    "Update the status of a Sentry issue directly from the AI assistant after verifying a fix."
  )
end

def sync_commands
  source = File.join(CLAUDE_DIR, "commands")
  target = File.join(OPENCODE_DIR, "commands")
  @commands = []

  Dir.glob(File.join(source, "**", "*.md")).sort.each do |file|
    rel = file.delete_prefix(source + File::SEPARATOR)
    fm, body = split_frontmatter(file)
    next if fm.nil?

    kept = []
    in_description = false
    fm.each do |line|
      if line.start_with?("description:")
        kept << line
        in_description = true
      elsif in_description && (line =~ /^\s/ || line.chomp.empty?)
        kept << line
      else
        in_description = false
      end
    end
    next if kept.empty?

    out_path = File.join(target, rel)
    write_with_frontmatter(out_path, kept, adapt_command_body(body))
    @commands << rel.delete_suffix(".md")
    puts "Command: #{rel}"
  end

  prune("command", @commands, target)
end

# --- rules -----------------------------------------------------------------

def sync_rules
  source = File.join(CLAUDE_DIR, "rules")
  target = File.join(OPENCODE_DIR, "rules")
  @rules = []

  Dir.glob(File.join(source, "*.md")).sort.each do |file|
    _fm, body = split_frontmatter(file)
    out_path = File.join(target, File.basename(file))
    write_file(out_path, body)
    @rules << File.basename(file, ".md")
    puts "Rule: #{File.basename(file)}"
  end

  prune("rule", @rules, target)
end

# --- skills ----------------------------------------------------------------

def sync_skills
  source = File.join(CLAUDE_DIR, "skills")
  target = SKILLS_TARGET_DIR
  @skills = []

  Dir.glob(File.join(source, "*")).sort.each do |dir|
    next unless File.directory?(dir)
    next unless File.exist?(File.join(dir, "SKILL.md"))

    name = File.basename(dir)
    FileUtils.rm_rf(File.join(target, name), secure: true)
    FileUtils.mkdir_p(target)
    FileUtils.cp_r(dir, File.join(target, name))
    @skills << name
    puts "Skill: #{name}"
  end

  prune("skill", @skills, target)
end

# --- main ------------------------------------------------------------------

sync_agents
sync_commands
sync_rules
sync_skills

@manifest = {
  "agent" => @agents ||= [],
  "command" => @commands ||= [],
  "rule" => @rules ||= [],
  "skill" => @skills ||= []
}
FileUtils.mkdir_p(OPENCODE_DIR)
File.write(MANIFEST_PATH, @manifest.keys.sort.flat_map { |s| @manifest[s].map { |n| "#{s}:#{n}" } }.join("\n") + "\n")

puts "Synced Claude Code config to opencode."
