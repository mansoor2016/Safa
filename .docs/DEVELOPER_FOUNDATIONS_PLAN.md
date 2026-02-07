# Safa Developer Tooling Plan (Local-First)

## Purpose

Define only the tooling needed to keep local development fast and reliable for a solo developer.

Terminology standard:
- `full checks` (renamed from `fast-ci`)

## Why This Speeds Up Development

1. Auto-formatting removes style churn and reduces manual cleanup.
2. Lint catches obvious issues before they become debugging sessions.
3. One repeatable `full checks` flow removes command guesswork.
4. Agents produce more consistent output when tooling expectations are explicit.

## Scope

- In scope: formatter, linter, local check scripts, guidance updates.
- Out of scope: branch governance, CI, branch protection, team process policy.

## Tooling Foundations

### 1) Formatting

- Add `.swiftformat` with deterministic, low-surprise rules.
- Apply format-on-change during iteration.

### 2) Linting

- Add `.swiftlint.yml` with a small, low-noise ruleset.
- Keep style rules non-blocking initially.
- Keep correctness/maintainability rules blocking in `full checks`.

### 3) Local Verification Workflow

1. `quick checks` (during coding):
- Format changed Swift files.
- Lint changed Swift files.
- Run targeted tests for touched modules/classes.

2. `full checks` (required before commit):
- Build app target.
- Run `SafaTests` in series.
- Validate repo-wide formatting and linting.

### 4) Local Scripts

Planned scripts:
- `scripts/dev/quick-checks.sh`
- `scripts/dev/full-checks.sh`

Script requirements:
- Concise output suitable for agent use.
- Deterministic command order.
- Non-zero exit on any failure.

### 5) Optional Pre-Commit Hook

- Format and lint staged Swift files only.
- Do not run full simulator tests inside the hook.
- Keep bypass available (`--no-verify`) for emergency local iteration.

## Rollout

### Phase A
- Align documentation wording to `full checks`.
- Link this plan from guidance docs.

### Phase B
- Add `.swiftformat` and `.swiftlint.yml`.
- Add `scripts/dev/quick-checks.sh` and `scripts/dev/full-checks.sh`.

### Phase C
- Use `quick checks` during edits.
- Run `full checks` before each commit.
- Tune lint rules only when false positives are observed.

## Acceptance Criteria

- `full checks` terminology is consistent in guidance docs.
- Tooling runs from documented scripts without manual command assembly.
- Format and lint outputs are stable and low-noise.
- `full checks` is reproducible on the local machine.

## Documentation Integration

1. `CLAUDE.md`
- Keep `/build` and `/test` as preferred execution path.
- Reference `quick checks` and `full checks` local workflow.

2. `.docs/TECHNICAL.md`
- Add developer tooling subsection under Testing Strategy.
- Define quick vs full checks expectations.

3. `.docs/TASKS.md`
- Track only tooling items: formatter, linter, quick/full scripts.
