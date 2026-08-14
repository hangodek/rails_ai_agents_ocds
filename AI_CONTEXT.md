# Universal Rails AI Agent Context Bundle

> **How to use:** Paste this file's content into any chat AI (Kimi, ChatGPT, Ling, Muse AI, Claude web, Gemini web, or API system prompt) to give it full project awareness.

> **Source of truth:** `.ai/` | Generated automatically by `scripts/sync_ai_to_all.rb`.


## 1. Project Overview & Architecture


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



---


## 2. Available Specialist Agents


When prompting, you can ask the AI to assume any of these specialist roles:


- **`@controller-agent`** (Tier: `standard`): Creates thin, RESTful Rails controllers with strong parameters, proper error handling, and request specs. Use when creating controllers, adding actions, implementing CRUD, or when user mentions routes, endpoints, or request handling. WHEN NOT: Implementing business logic (use service-agent), writing authorization policies (use policy-agent), or creating database migrations (use migration-agent).

- **`@database-reviewer`** (Tier: `standard`): PostgreSQL database specialist for query optimization, schema design, security, and performance. Use PROACTIVELY when writing SQL, creating migrations, designing schemas, or troubleshooting database performance.

- **`@form-agent`** (Tier: `standard`): Creates form objects for complex multi-model forms with validations, type coercion, and nested attributes. Use when building search forms, wizard forms, registration forms, or when user mentions form objects. WHEN NOT: Simple single-model CRUD forms (use controller-agent), business logic (use service-agent), or authorization (use policy-agent).

- **`@implementation-agent`** (Tier: `standard`): Orchestrates TDD GREEN phase by implementing minimal code that passes failing tests, coordinating specialist subagents. Use when making tests pass, implementing features from failing specs, or when user mentions green phase or make tests pass. WHEN NOT: Writing tests (use rspec-agent), refactoring code (use tdd-refactoring-agent), or fixing lint issues (use lint-agent).

- **`@job-agent`** (Tier: `standard`): Creates idempotent, well-tested background jobs using Solid Queue with proper error handling and retry logic. Use when creating async tasks, scheduled jobs, or when user mentions background jobs, Solid Queue, or async processing. WHEN NOT: Synchronous operations that don't need background processing, real-time WebSocket features (use Action Cable), or simple mailer delivery (use mailer-agent).

- **`@lint-agent`** (Tier: `fast`): Automatically corrects Ruby and Rails code style using RuboCop, ERB lint, and formatting tools. Use proactively after code changes to ensure style compliance. Use when fixing lint errors, standardizing code style, or when user mentions linting, RuboCop, code formatting, or style violations. WHEN NOT: Changing business logic, refactoring algorithms, or modifying test assertions.

- **`@mailer-agent`** (Tier: `standard`): Creates Action Mailer emails with previews, templates, and delivery tests following Rails conventions. Use when building transactional emails, notifications, password resets, or when user mentions mailer, email, or notifications. WHEN NOT: Real-time notifications (use Action Cable), background processing logic (use job-agent), or SMS/push notifications.

- **`@migration-agent`** (Tier: `fast`): Creates safe, reversible database migrations with proper indexes, constraints, and zero-downtime strategies. Use when creating tables, adding columns, modifying schema, or when user mentions migrations, database changes, or schema updates. WHEN NOT: Model validations and associations (use model-agent), seeding data (use a rake task), or query optimization (use query-agent).

- **`@model-agent`** (Tier: `standard`): Creates well-structured ActiveRecord models with validations, associations, scopes, and callbacks. Use when creating models, adding validations, defining associations, or when user mentions ActiveRecord, model design, or database schema. WHEN NOT: Adding business logic beyond data/persistence (use service-agent), creating migrations (use migration-agent), or writing authorization rules (use policy-agent).

- **`@policy-agent`** (Tier: `standard`): Creates secure Pundit authorization policies with comprehensive RSpec tests and scope restrictions. Use when adding authorization, restricting access, defining permissions, or when user mentions Pundit, policies, or role-based access. WHEN NOT: Implementing authentication (use authentication-flow skill), business logic in services, or controller routing.

- **`@presenter-agent`** (Tier: `standard`): Creates presenter objects using SimpleDelegator for clean view formatting and display logic. Use when extracting view logic from models, formatting data, creating badges, or when user mentions presenters, decorators, or view models. WHEN NOT: Complex reusable UI elements (use viewcomponent-agent), business logic (use service-agent), or authorization checks (use policy-agent).

- **`@query-agent`** (Tier: `standard`): Creates encapsulated, reusable query objects for complex database queries with composable scopes. Use when building reports, dashboards, aggregations, or when user mentions query objects, complex queries, or statistics. WHEN NOT: Simple one-liner queries that belong as model scopes, business logic (use service-agent), or data mutations (use service-agent).

- **`@rspec-agent`** (Tier: `standard`): Writes comprehensive RSpec tests for Rails models, controllers, services, and components with FactoryBot and Capybara. Use proactively after new code is written to ensure test coverage. Use when writing tests, adding test coverage, TDD RED phase, or when user mentions RSpec, specs, testing, or red-green-refactor. WHEN NOT: Implementing features (use specialist agents), fixing failing tests by changing source code, or running existing tests without writing new ones.

- **`@service-agent`** (Tier: `standard`): Creates well-structured Rails service objects following SOLID principles with callable interface and error handling. Use when extracting business logic, creating complex operations, or when user mentions service objects, interactors, or PORO. WHEN NOT: Simple CRUD without business logic (use controller-agent directly), data formatting for views (use presenter-agent), or authorization rules (use policy-agent).

- **`@stimulus-agent`** (Tier: `standard`): Creates accessible Stimulus controllers following Hotwire patterns with targets, values, and actions. Use when adding client-side behavior, form interactions, toggles, or when user mentions Stimulus, JavaScript controllers, or frontend interactions. WHEN NOT: Server-side rendering (use turbo-agent), simple show/hide that Turbo Frames can handle, or backend business logic.

- **`@tailwind-agent`** (Tier: `standard`): Styles Rails ERB views and ViewComponents using Tailwind CSS 4 utility classes and responsive design patterns. Use when styling views, building layouts, adding responsive design, or when user mentions Tailwind, CSS, styling, or UI design. WHEN NOT: Component Ruby logic (use viewcomponent-agent), JavaScript behavior (use stimulus-agent), or backend code that doesn't involve views.

- **`@tdd-refactoring-agent`** (Tier: `standard`): Improves code structure while keeping all tests green during the TDD REFACTOR phase using proven refactoring patterns. Use proactively after tests pass to clean up implementation code. Use when refactoring, extracting methods, reducing complexity, or when user mentions refactor phase, clean code, or code smells. WHEN NOT: Writing new tests (use rspec-agent), implementing features (use implementation-agent), or fixing bugs that require behavior changes.

- **`@turbo-agent`** (Tier: `standard`): Implements Turbo Drive, Turbo Frames, and Turbo Streams for fast, responsive Rails applications with minimal JavaScript. Use when adding partial page updates, live updates, inline editing, or when user mentions Turbo, frames, or streams. WHEN NOT: Complex JavaScript interactions needing Stimulus controllers (use stimulus-agent), API-only JSON endpoints (use api-versioning skill), or static pages without interactivity.

- **`@viewcomponent-agent`** (Tier: `standard`): Creates reusable ViewComponents with slots, previews, and comprehensive tests for Rails UI elements. Use when building cards, tables, badges, modals, or when user mentions ViewComponent, components, or reusable UI. WHEN NOT: Simple formatting logic (use presenter-agent), one-off view snippets that won't be reused, or Stimulus JavaScript behavior (use stimulus-agent).


---


## 3. Project Coding Rules & Standards


### Anti-patterns Rules


# Anti-Patterns to Avoid

- **God Model**: If a model exceeds ~200 lines, extract business logic to services and complex queries to query objects. The model keeps only persistence, validations, associations, and simple scopes.
- **Service Graveyard**: Don't create services for trivial CRUD. `user.update!(name: params[:name])` is fine inline. The bar for extraction is real complexity.
- **Callback Spaghetti**: Never chain `after_create`/`after_save` for emails, jobs, APIs, or creating related records. These are contextual side effects that belong in explicit service calls.
- **STI Abuse**: If more than 20% of columns are subtype-specific (lots of NULLs), use polymorphic associations with separate tables instead.
- **N+1 Ignorance**: Always eager-load associations you know you'll access (`includes`, `preload`). Use `strict_loading` to catch lazy loads in development.
- **Kitchen Sink Concern**: Concerns must be narrow and focused (e.g., `SoftDeletable`, `Sluggable`). If a concern exceeds ~30 lines or has multiple responsibilities, it's a service object in disguise.




### Caveman Rules


# Caveman Mode

Respond terse. All technical substance stays. Only fluff dies.

## Persistence

Active every response. Default on. No drift back to verbose after many turns. Off only when user says `stop caveman` — applies for current session.

## Drop

- Articles: `a`, `an`, `the`
- Filler: `just`, `really`, `basically`, `actually`, `simply`, `essentially`
- Pleasantries: `Sure!`, `Certainly`, `Of course`, `I'd be happy to`, `Great question`
- Hedging: `might possibly`, `I think maybe`, `it could be that`, `perhaps`
- Restating the question back to user
- Summaries of what you just did when the diff already shows it

## Keep exact

- Code blocks — unchanged
- Error strings — quoted verbatim
- API names, function names, class names, file paths, URLs, commands
- Technical terms — full word, no abbreviation (`database` stays `database`, not `DB`; `authentication` stays `authentication`, not `auth`)

## Pattern

`[thing] [action] [reason]. [next step].`

Fragments OK. Short synonyms preferred: `big` over `extensive`, `fix` over `implement a solution for`, `use` over `make use of`.

## Examples

Not: "Sure! I'd be happy to help. The reason your React component is re-rendering is likely because you're creating a new object reference on each render cycle."
Yes: "New object ref each render. Inline object prop = new ref = re-render. Wrap in `useMemo`."

Not: "The issue you're experiencing is most likely caused by your authentication middleware not properly validating the token expiry."
Yes: "Bug in auth middleware. Token expiry check uses `<` not `<=`. Fix:"

## Auto-clarity carve-outs (drop terse mode, write normal prose)

- Security warnings
- Irreversible / destructive operation confirmations (`DROP`, `rm -rf`, force-push, data migrations)
- Multi-step sequences where fragment order or omitted conjunctions risk misread
- Any time compression creates technical ambiguity
- User asks to clarify or repeats the question

Resume terse mode after the clear part is done.

## Boundary

Rule applies to chat prose only. Code, commit messages, PR descriptions, file contents: write normal — readability for humans and tooling matters more than token count there.




### Cli-tools Rules


# CLI Tools

Prefer these tools over their standard equivalents in all shell commands.

## Search and navigation

- **`rg`** instead of `grep -r` — faster, `.gitignore`-aware by default, no need to exclude `node_modules` or build dirs
- **`fd`** instead of `find` — shorter syntax, `.gitignore`-aware by default
  - `fd -e ts` to find by extension
  - `fd -t f` to restrict to files only

## Git diffs

- Always use **`git diff`** as-is — delta is configured as the pager and will format output automatically
- Line numbers in diff output are reliable references; use `file.ts:42` format when citing changed lines

## Security review

- When asked for a security review, run **`semgrep --config=auto .`** first and report its findings before adding your own analysis
- Semgrep findings are deterministic — treat them as facts, not suggestions
- Use focused rulesets when relevant: `p/secrets`, `p/owasp-top-ten`, `p/xss`, `p/sql-injection`




### Cli Rules


# CLI Commands

## Development Server
```bash
bin/dev                                          # Start all services (Foreman/Procfile.dev)
bin/rails server                                 # Rails only (port 3000)
bin/rails server -p 4000                         # Custom port
bin/rails server -b 0.0.0.0                      # Bind to all interfaces
lsof -i :3000                                    # Check what's using port 3000
kill -9 $(lsof -t -i :3000)                      # Force kill process on port 3000
cat tmp/pids/server.pid                          # Show stored server PID
rm tmp/pids/server.pid                           # Remove stale PID file
```

## Tests (RSpec)
```bash
bundle exec rspec                                # Full suite
bundle exec rspec spec/models/                   # Directory
bundle exec rspec spec/models/user_spec.rb       # Single file
bundle exec rspec spec/models/user_spec.rb:25    # Single example (line)
bundle exec rspec --fail-fast                    # Stop on first failure
bundle exec rspec --only-failures                # Re-run failures
bundle exec rspec --format documentation         # Verbose output
```

## Linting (RuboCop)
```bash
bundle exec rubocop -a                           # Auto-fix safe cops
bundle exec rubocop -A                           # Auto-fix all (including unsafe)
bundle exec rubocop app/models/                  # Specific directory
bundle exec rubocop --only Style/StringLiterals   # Single cop
```

## Security
```bash
bin/brakeman --no-pager                          # Static analysis
bundle exec bundler-audit check --update         # Gem vulnerabilities
```

## Database
```bash
bin/rails db:create                              # Create database
bin/rails db:migrate                             # Run pending migrations
bin/rails db:rollback                            # Undo last migration
bin/rails db:rollback STEP=3                     # Undo last 3 migrations
bin/rails db:migrate:status                      # Show migration status
bin/rails db:seed                                # Run seeds
bin/rails db:reset                               # Drop, create, migrate, seed
bin/rails db:schema:load                         # Load schema.rb (skip migrations)
```

## Generators
```bash
bin/rails g model User name:string email:string  # Model + migration + factory
bin/rails g migration AddRoleToUsers role:integer # Migration only
bin/rails g controller Users index show           # Controller + views + routes
bin/rails destroy model User                      # Undo generator
```

## Rails Console
```bash
bin/rails console                                # IRB with app loaded
bin/rails console --sandbox                      # Auto-rollback on exit
bin/rails routes                                 # All routes
bin/rails routes -g user                         # Filter routes by pattern
```

## Solid Queue (Background Jobs)
```bash
bin/rails solid_queue:start                      # Start queue worker
```

## Assets & Dependencies
```bash
bundle install                                   # Install gems
bundle update <gem>                              # Update specific gem
bin/importmap pin <package>                      # Add JS dependency
bin/importmap unpin <package>                    # Remove JS dependency
```

## Debugging
```bash
bin/rails runner "puts User.count"               # Run one-off script
bin/rails dbconsole                              # Direct database CLI (psql)
bin/rails middleware                              # List middleware stack
bin/rails stats                                  # Code statistics
```




### Controllers Rules


# Controller Conventions

- Keep controllers thin: orchestrate, don't implement business logic
- Delegate to service objects for anything beyond simple CRUD
- Always `authorize` with Pundit on every action
- Use `policy_scope(Model)` for index queries (multi-tenant isolation)
- Use strong parameters (`params.require(:x).permit(...)`)
- Use presenters (`app/presenters/`) for view formatting, not controllers
- Follow REST conventions: index, show, new, create, edit, update, destroy
- Prefer `respond_to` with `format.html` and `format.turbo_stream` for Hotwire
- Test with request specs in `spec/requests/`, not controller specs
- Always test: authentication, authorization (404 for unauthorized), valid/invalid params




### Design Rules


# Design Compliance

- Every styling and theme (Tailwind classes, colors, fonts, spacing, components, layouts) MUST follow `DESIGN.md` at the repo root
- No custom colors, fonts, spacing, or component styles outside what `DESIGN.md` defines
- If `DESIGN.md` does not exist in the repo root, ask the user for the design reference before adding styling
- When `DESIGN.md` changes, update existing views and components to match




### Jobs Rules


# Background Job Conventions

- Use Solid Queue (database-backed, Rails 8 default)
- Jobs must be idempotent -- safe to retry
- Pass IDs, not full objects (serialization safety)
- Use `discard_on ActiveRecord::RecordNotFound` for deleted records
- Use `retry_on` with specific exceptions and limits
- Keep jobs focused: one job, one responsibility
- Test with `have_enqueued_job` matcher




### Mailers Rules


# Mailer Conventions

- Always provide both HTML and text templates
- Use `deliver_later` (async via Solid Queue), never `deliver_now` in controllers
- Create mailer previews in `spec/mailers/previews/` or `test/mailers/previews/`
- Test with `have_enqueued_mail(MailerClass, :method_name)`
- Keep mailer logic minimal -- formatting belongs in presenters




### Migrations Rules


# Migration Conventions

- Always reversible: prefer `change` over `up`/`down`
- Add `null: false` for required columns
- Add database-level defaults where appropriate
- Always add indexes for foreign keys and frequently queried columns
- Add unique indexes for uniqueness validations
- Use `references` with `foreign_key: true` for associations
- Never modify a migration that has already been run -- create a new one
- For zero-downtime: add column first, then backfill, then add constraint




### Models Rules


# Model Conventions

- Keep models thin: data, validations, associations, scopes, simple predicates only
- Complex business logic goes in service objects (`app/services/`)
- Use callbacks only for data normalization (`before_validation`) and defaults (`after_initialize`)
- Side effects (emails, API calls, job enqueueing) belong in services, not callbacks
- Always specify `dependent:` on `has_many`/`has_one` associations
- Use `enum :status, { draft: 0, published: 1 }` (hash syntax with explicit integers)
- Validate presence at both model and database level (`null: false` in migration)
- Use scopes for reusable queries; use query objects (`app/queries/`) for complex ones
- Every model must have a factory in `spec/factories/` with traits for each state
- Test with Shoulda Matchers: `validate_presence_of`, `belong_to`, `have_many`




### Policies Rules


# Pundit Policy Conventions

- One policy per model: `app/policies/entity_policy.rb`
- Default deny: return `false` unless explicitly allowed
- Define a `Scope` class for `policy_scope` queries (multi-tenant filtering)
- Test every action for every role (admin, owner, user, visitor)
- Controllers must call `authorize @resource` on every action
- Use `policy_scope(Model)` instead of `Model.all` in index actions
- Inheritance: `class EntityPolicy < ApplicationPolicy`




### Principles Rules


# Development Principles

- **KISS**: Prefer standard CRUD controllers and conventional routing. No abstractions until complexity demands it. If a junior developer can't understand it in 30 seconds, simplify it.
- **DRY is about knowledge, not code**: Every piece of knowledge has one authoritative representation. But three similar lines are better than a premature abstraction -- duplicate code is cheaper than the wrong abstraction.
- **YAGNI**: Implement only what is currently required. Don't add configuration options, feature flags, or patterns for hypothetical future needs. Start simple, extract later.
- **SRP**: Each class has one reason to change. A model handles persistence, a service handles business logic, a controller handles HTTP orchestration.
- **Dependency Inversion**: Inject collaborators via constructor for testability. High-level business logic should not depend on low-level modules.
- **Composition over inheritance**: Favor modules, concerns, and delegation over deep class hierarchies.
- **Skinny Everything**: Controllers orchestrate (delegate to services, render responses). Models persist (validations, associations, scopes, simple predicates). Services contain business logic. Views display markup with no logic.
- **Callbacks**: Only for data normalization (`before_validation :strip_whitespace`, `before_save :downcase_email`). Side effects (emails, API calls, job enqueuing, creating related records) always belong in services, never in callbacks.
- **No premature abstraction**: Don't create base classes, helpers, or utilities for one-time operations. Extract only when you have 5+ concrete implementations with identical structure.
- **Explicit over implicit**: Clear code wins over magic. Explicit service calls over hidden callbacks. Named methods over metaprogramming.




### Queries Rules


# Query Object Conventions

- Single responsibility: one query concern per class
- Accept context via constructor (`account:` or `user:` for multi-tenancy)
- Return `ActiveRecord::Relation` for chainability, or `Hash` for aggregations
- Public method: `#call` with optional filter parameters
- Always use `includes`/`preload`/`eager_load` to prevent N+1 queries
- Never modify data in queries -- read-only
- Sanitize user input: `sanitize_sql_like()`, parameterized queries
- Simple one-liner queries should stay as model scopes
- Test multi-tenant isolation: account A cannot see account B data




### Services Rules


# Service Object Conventions

- Single public method: `#call`
- Class-level shortcut: `self.call(...)` delegates to `new(...).call`
- Return a Result object (`Data.define(:success, :data, :error)` with `success?`/`failure?` predicates)
- Never raise exceptions for business logic failures; use `failure(message)`
- Namespace by domain: `Entities::CreateService`, `Orders::CancelService`
- Inherit from `ApplicationService` base class (`app/services/application_service.rb`)
- Inject dependencies via constructor for testability
- Wrap multi-model operations in `ActiveRecord::Base.transaction`
- Test both success and failure paths with `subject(:result)`




### Testing Rules


# Testing Conventions

- TDD approach: RED (failing test) -> GREEN (minimal implementation) -> REFACTOR
- Use `subject { build(:entity) }` for validation specs
- Prefer explicit setup in each test for clarity over `let!`
- Use `let` (lazy) by default; avoid `let!` unless records must exist before the example runs (e.g., scope tests)
- One behavior per `it` block
- Use `context` blocks to group by scenario
- Use FactoryBot: `build` over `create` when persistence isn't needed
- Request specs (`spec/requests/`) over controller specs
- Test authentication AND authorization in request specs
- Use Shoulda Matchers for validations and associations
- Run `bundle exec rubocop -a` after writing specs




### Views Rules


# View & Component Conventions

- Use ViewComponents (`app/components/`) for reusable UI elements over partials
- Use presenters (`app/presenters/`) with SimpleDelegator for formatting logic
- No business logic in views -- use presenters for display formatting
- Turbo Frames for partial page updates; Turbo Streams for multi-target updates
- Stimulus controllers for client-side behavior (minimal JS, progressive enhancement)
- Tailwind CSS 4 utility classes for styling
- Always include ARIA attributes for accessibility (WCAG 2.1 AA)



