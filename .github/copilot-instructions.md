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
