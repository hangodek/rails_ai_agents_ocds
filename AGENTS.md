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

- **Canonical config lives in `.claude/`** (Claude Code). opencode mirrors it under `.opencode/` and `.agents/skills/`; the model is set in `opencode.json` (default `opencode/deepseek-v4-flash-free`).
- **Specialist agents** (`.opencode/agents/*.md`): delegate layer work via the `task` tool — e.g. `model-agent`, `service-agent`, `rspec-agent`, `viewcomponent-agent`, `lint-agent`. Subagents inherit the session model.
- **Slash commands** (`.opencode/commands/**`): `/feature-plan`, `/sdd:*`, `/sentry:*`, etc.
- **Rules** (`.opencode/rules/*.md`) are loaded into every session via `instructions` in `opencode.json`.
- **Hooks** run via `.opencode/plugins/project-hooks.ts`: destructive-command guard, RuboCop/ERB auto-format after edits, session status logging, desktop notifications.
- **Keep in sync:** after changing anything under `.claude/`, run `scripts/sync_claude_to_opencode.sh` and restart opencode.

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
