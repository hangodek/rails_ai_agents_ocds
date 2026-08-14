# Rails AI Agents (Universal Multi-AI Edition)

> 🚀 **A universal, provider-agnostic AI coding agent setup for Ruby on Rails.**
> Forked from the original Rails AI Agents project and enhanced with a universal sync engine, abstract model tiers, and automated multi-tool configuration.

Drop this into any Rails 8/7 project and your AI assistant instantly knows your architecture, TDD workflows, naming conventions, and production Rails patterns.

---

## ⚡ Quick Start (New or Existing Project)

Install the entire setup into your Rails project in **5 seconds with zero manual copy-pasting**:

```bash
# Run this inside your Rails project root:
curl -fsSL https://raw.githubusercontent.com/hangodek/rails_ai_agents_ocds/main/install.sh | bash
```

**What this does:**
1. Downloads the canonical `.ai/` configuration.
2. Automatically generates native config files for all your AI tools (Cursor, Claude, opencode, Windsurf, Gemini, etc.).
3. Appends generated files to `.gitignore` so your repository stays clean and uncluttered.

---

## 🛠️ Supported AI Tools & Platforms

Open your Rails folder in any of these tools — **conventions and rules auto-load automatically**:

| Tool / Platform | Type | How It Auto-Loads |
|---|---|---|
| **Cursor** | IDE | Reads `AGENTS.md` and path-scoped `.cursor/rules/*.mdc` |
| **Claude Code** | CLI / Agent | Reads `CLAUDE.md` and `.claude/` |
| **opencode** (DeepSeek, etc.) | CLI / Agent | Reads `AGENTS.md` and `.opencode/` via `opencode.json` |
| **Antigravity** (Google Gemini) | IDE / Agent | Auto-detects `AGENTS.md` |
| **Gemini CLI** | CLI / Agent | Reads `GEMINI.md` |
| **Windsurf** (Cascade) | IDE | Reads `AGENTS.md` and `.windsurfrules` |
| **Cline** (VS Code) | IDE Ext | Reads `AGENTS.md` and `.clinerules/` |
| **Continue.dev** | IDE Ext | Reads `.continue/rules/` |
| **Aider** | Terminal CLI | Reads `CONVENTIONS.md` via `.aider.conf.yml` |
| **GitHub Copilot** | IDE Ext | Reads `AGENTS.md` and `.github/instructions/` |
| **MiMo Code / Kimi Code / Muse Code** | CLI / Agent | Native `AGENTS.md` discovery |
| **Web Chat AIs** (ChatGPT, Kimi, Ling, Claude web) | Web / API | Paste `AI_CONTEXT.md` (single all-in-one bundle) |

---

## 🎯 Key Features

### 1. 🤖 19 Specialized Subagents
Domain-expert agents configured with precise tool permissions and clear delegation boundaries:
- **Architecture & Logic:** `@model-agent`, `@service-agent`, `@query-agent`, `@policy-agent`, `@form-agent`
- **Controller & API:** `@controller-agent`, `@migration-agent`
- **Frontend & UI:** `@viewcomponent-agent`, `@tailwind-agent`, `@turbo-agent`, `@stimulus-agent`, `@presenter-agent`
- **Jobs & Mailers:** `@job-agent`, `@mailer-agent`
- **TDD & Quality:** `@rspec-agent`, `@implementation-agent` (GREEN phase), `@tdd-refactoring-agent`, `@lint-agent`
- **Database:** `@database-reviewer` (PostgreSQL optimization)

### 2. 📜 15 Rails Coding Rules & Conventions
Path-scoped instructions that guide AI behavior during file edits:
- Models, Controllers, Services, Queries, Policies, Jobs, Mailers, Migrations, Views, Testing, Anti-patterns, Principles, CLI workflows, and Token reduction (`caveman.md`).

### 3. 🧠 18 Workflow Skills
On-demand specialized playbooks including:
- `code-review`, `security-audit` (Brakeman / OWASP), `accessibility-review` (WCAG 2.2 AA), `performance-optimization` (N+1 query detection), `solid-queue-setup`, `action-cable-patterns`, and more.

### 4. 📋 Spec-Driven Development (SDD) Kit
A complete specification-to-implementation pipeline with 26 slash commands:
- `/feature-spec` & `/sdd:specify`: Structured interview and spec generation
- `/sdd:plan` & `/sdd:tasks`: Technical planning and task breakdown
- `/sdd:implement`: TDD task execution with progress tracking
- `/sdd-change:*`: Lightweight fast-track mode for bug fixes and small tweaks

### 5. 📦 Universal Context Bundle (`AI_CONTEXT.md`)
A single self-contained markdown file aggregating project architecture, rules, and agent definitions — perfect for pasting into ChatGPT, Claude.ai Projects, Gemini Gems, or LLM API system prompts.

---

## 📖 Daily Usage Guide

### Using with IDE & Terminal Agents
Just open your project in your tool (Cursor, Windsurf, Claude Code, etc.). The agent will automatically follow your Rails architecture, TDD workflows, and testing commands (`bundle exec rspec`).

### Using with Web Chat AIs
1. Open `AI_CONTEXT.md`.
2. Copy and paste its content into your chat or set it as a Custom GPT / Claude Project system prompt.

### Updating Rules or Agents
Always make edits in the canonical source folder **`.ai/`**:

```bash
# 1. Edit rules, skills, or agents in .ai/
# 2. Run the sync command:
scripts/sync_all.sh

# 3. Commit changes to git
git add .ai/ AGENTS.md
git commit -m "chore: update Rails AI conventions"
```

The sync script automatically propagates your changes to all 10+ provider targets.

---

## 📁 Repository Structure

```
├── .ai/                    # ⭐ CANONICAL SOURCE OF TRUTH (edit here)
│   ├── agents/             # 19 specialist subagents (abstract model tiers)
│   ├── commands/           # 26 slash commands & SDD pipelines
│   ├── rules/              # 15 coding rules and architectural constraints
│   ├── skills/             # 18 task and knowledge playbooks
│   └── settings/           # Model tiers, base hooks, provider definitions
├── AGENTS.md               # Open standard entry point (read by Cursor, MiMo, etc.)
├── CLAUDE.md               # Claude Code entry point (@AGENTS.md)
├── GEMINI.md               # Gemini CLI entry point (@AGENTS.md)
├── AI_CONTEXT.md           # Generated single-file bundle for web chat AIs
├── install.sh              # One-line zero-copy installer
└── scripts/
    ├── sync_ai_to_all.rb   # Master multi-provider sync engine
    └── sync_all.sh         # Sync convenience command
```

---

## 📄 License

MIT License. Free for personal and commercial Rails development.
