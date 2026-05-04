# AGENTS.md

This repository is a Claude Code / Codex hybrid plugin marketplace. It is being migrated from a Claude Code-only plugin marketplace into a dual Claude/Codex plugin collection.

## Current Source Of Truth

- Shared catalog metadata lives in `catalog/toymarket.json`.
- The migration design lives in `docs/dual-runtime-architecture.md`.
- Codex compatibility work is tracked in `CHECKLIST.codex.md`.

## Verification

Run the current Claude-compatible structural check:

```bash
python3 scripts/verify_repo.py --profile claude --full
```

Run the dual-runtime gate:

```bash
python3 scripts/verify_repo.py --profile dual
```

Both commands should pass before changing plugin metadata or generated manifests.

## Codex Registration

Register this local marketplace with Codex:

```bash
codex plugin marketplace add /Users/pulp/Desktop/Repositories/claude-toymarket
```

Register from GitHub instead:

```bash
codex plugin marketplace add wonjiko/claude-toymarket
```

Git marketplaces can be updated with:

```bash
codex plugin marketplace upgrade claude-toymarket
```

Local path marketplaces are not Git marketplaces, so `upgrade` does not apply to them.

## Editing Rules

- Treat `catalog/toymarket.json` as the source for marketplace and plugin manifest metadata.
- Keep shared behavior in `skills/`, `hooks/`, `references/`, `assets/`, and scripts.
- Treat `commands/*.md` as Claude-only adapters unless a Codex equivalent is explicitly added.
- Keep generated Claude/Codex manifest files in sync with `scripts/verify_repo.py --fix` rather than hand-editing them.
