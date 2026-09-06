# Active Gotchas

Keep only prevention rules that remain relevant to current work.

- **2026-09-06** — Broad negative filtering classified metadata such as
  `.ai-memory.toml` as product source and duplicated logic between Stop
  and pre-commit.
  **Rule**: Classify operational changes through the shared configurable
  source/ignore glob policy; ignore only clearly non-operational defaults.

- **2026-09-06** — Treating `scripts/**` and `tools/**` as tooling-only
  would hide executable product code.
  **Rule**: Never ignore those directories by default; let matching
  source globs classify their contents and require explicit project exclusions.

- **2026-09-06** — Retry-based release or optional integration behavior
  can silently weaken a real safety or integrity guarantee.
  **Rule**: Keep `error` and `fatal` results fail-closed until their stated
  recovery condition is satisfied; optional integrations may warn but
  must never bypass enforcement.
