# Project Configuration

## Tech Stack

- **Ruby** 3.3, **Rails** 8.1, **PostgreSQL**
- **Frontend:** Hotwire (Turbo + Stimulus), Tailwind CSS 4, ViewComponent
- **Testing:** RSpec, FactoryBot, Shoulda Matchers, Capybara
- **Auth:** `has_secure_password` (Rails 8 built-in), Pundit (authorization)
- **Background Jobs:** Solid Queue (database-backed, no Redis)
- **Caching:** Solid Cache | **WebSockets:** Solid Cable
- **Assets:** Propshaft + Import Maps (no Node.js)
- **Deployment:** Kamal 2 + Thruster

## Architecture

```
app/
  controllers/     # Thin. Delegates to services. Renders responses.
  models/          # Persistence: validations, associations, scopes, simple predicates.
  views/           # ERB markup only. No logic.
  services/        # Business logic. Orchestrates models, APIs, side effects.
  queries/         # Complex database queries. Returns relations or hashes.
  forms/           # Multi-model form objects.
  policies/        # Pundit authorization. Default deny.
  presenters/      # View formatting (SimpleDelegator).
  components/      # ViewComponents (reusable UI with tests).
  jobs/            # Background jobs (Solid Queue). Must be idempotent.
  mailers/         # Email delivery. Always HTML + text templates.
```

## Key Commands

```bash
# Tests
bundle exec rspec                              # Full suite
bundle exec rspec spec/path/to_spec.rb         # Specific file
bundle exec rspec spec/path/to_spec.rb:25      # Specific line

# Linting
bundle exec rubocop -a                         # Auto-fix Ruby
bundle exec rubocop -a app/models/             # Specific directory

# Security
bin/brakeman --no-pager                        # Static analysis
bundle exec bundler-audit check --update       # Gem vulnerabilities

# Database
bin/rails db:migrate                           # Run migrations
bin/rails db:migrate:status                    # Check status
bin/rails console                              # Interactive console
```

## Development Workflow

Follow **TDD: Red -> Green -> Refactor**:

1. **RED:** Write a failing test describing desired behavior
2. **GREEN:** Write minimal code to pass the test
3. **REFACTOR:** Improve code structure while keeping tests green

## Core Conventions

- **Skinny Everything:** Controllers orchestrate. Models persist. Services contain business logic. Views display.
- **Callbacks:** Only for data normalization (`before_validation`, `before_save`). Side effects (emails, jobs, APIs) belong in services.
- **Services:** `.call` class method, return Result objects, namespace by domain (`Entities::CreateService`).
- **No premature abstraction:** Don't extract until complexity demands it. Three similar lines > wrong abstraction.
- **Explicit > implicit:** Clear service calls over hidden callbacks. Named methods over metaprogramming.
- **Design compliance:** Every styling and theme (Tailwind classes, colors, components, layouts) MUST follow `DESIGN.md` at the repo root. No custom colors, fonts, spacing, or component styles outside what `DESIGN.md` defines.

See @docs/rails-development-principles.md for the complete development principles guide.

## AI Tooling

- **Canonical config lives in `.ai/`** — provider-agnostic. All tool-specific directories are generated from it.
- **Model tiers**: agents declare `model_tier: standard | fast | powerful`. Each provider maps these to real model IDs in `.ai/settings/model-tiers.yml`.
- **Specialist agents** (`**/agents/*.md`): delegate layer work — e.g. `model-agent`, `service-agent`, `rspec-agent`, `viewcomponent-agent`, `lint-agent`.
- **Slash commands** (`**/commands/**`): `/feature-plan`, `/sdd:*`, `/sentry:*`, etc.
- **Rules** (`**/rules/*.md`): loaded per provider's native convention (path-scoped for Claude, `instructions` list for opencode, `.mdc` for Cursor, bridge files for Copilot, etc.).
- **Universal context bundle**: `AI_CONTEXT.md` at repo root contains all conventions in a single file for any web chat AI (Kimi, ChatGPT, Ling, Muse AI, Claude web, Gemini web) or custom system prompt.
- **Keep in sync:** after changing anything under `.ai/`, run `ruby scripts/sync_ai_to_all.rb`.

### Supported AI Tools & Platforms

| Platform / Tool | Type | Integration Point | Auto-Load Mechanism |
|---|---|---|---|
| **Claude Code** | CLI / Agent | `.claude/`, `CLAUDE.md` | Auto-detects `CLAUDE.md` / `.claude/` |
| **opencode** (any model) | CLI / Agent | `.opencode/`, `opencode.json` | Auto-loads `opencode.json` instructions |
| **Antigravity** (Gemini) | IDE / Agent | `.agents/`, `AGENTS.md` | Auto-detects `AGENTS.md` |
| **Gemini CLI** | CLI / Agent | `.gemini/`, `GEMINI.md` | Auto-detects `GEMINI.md` |
| **Cursor** | IDE | `.cursor/rules/*.mdc`, `AGENTS.md` | Auto-loads `.cursor/rules/` & `AGENTS.md` |
| **Windsurf** | IDE | `.windsurfrules`, `AGENTS.md` | Auto-loads `.windsurfrules` & `AGENTS.md` |
| **Cline** | IDE Ext | `.clinerules/`, `AGENTS.md` | Auto-loads `.clinerules/` & `AGENTS.md` |
| **Continue.dev** | IDE Ext | `.continue/rules/` | Auto-loads `.continue/rules/` |
| **Aider** | CLI | `CONVENTIONS.md`, `.aider.conf.yml` | Auto-reads `CONVENTIONS.md` via config |
| **GitHub Copilot** | IDE Ext | `.github/instructions/`, `AGENTS.md` | Auto-reads instructions & `AGENTS.md` |
| **MiMo Code / Kimi Code / Muse Code** | CLI / Agent | `AGENTS.md`, `CLAUDE.md` | Native `AGENTS.md` discovery |
| **Chat AIs** (Kimi, Ling, ChatGPT, etc.) | Web Chat / API | `AI_CONTEXT.md` | Paste `AI_CONTEXT.md` or set as system prompt |

## Naming Conventions

| Layer | Pattern | Example |
| ------- | --------- | --------- |
| Model | Singular PascalCase | `Entity`, `OrderItem` |
| Controller | Plural PascalCase | `EntitiesController` |
| Service | Namespaced + `Service` | `Entities::CreateService` |
| Query | Namespaced + `Query` | `Entities::SearchQuery` |
| Policy | Singular + `Policy` | `EntityPolicy` |
| Job | Descriptive + `Job` | `ProcessPaymentJob` |
| Presenter | Singular + `Presenter` | `EntityPresenter` |
| Form | Descriptive + `Form` | `EntityRegistrationForm` |
