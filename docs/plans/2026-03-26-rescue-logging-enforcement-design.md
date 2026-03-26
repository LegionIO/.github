# Design: Rescue Block Logging Enforcement

## Problem Statement

Across the LegionIO ecosystem (~80+ gems), rescue blocks sometimes swallow exceptions silently — no log call, no re-raise, no visibility. This creates invisible failure modes that are extremely difficult to debug in production, especially in an async job engine where exceptions can cascade across AMQP boundaries.

There are two logging surfaces in Legion:

1. **Direct singleton**: `Legion::Logging.debug/info/warn/error/fatal` — used in framework code
2. **Helper mixin**: `log.debug/info/warn/error/fatal` — via `Legion::Logging::Helper`, included in all LEX extensions through `Helpers::Lex`

Both are valid. The problem is rescue blocks that use **neither**.

## Current State

A scan of `lib/**/*.rb` across all repos reveals:

- ~58 rescue blocks that don't capture the exception variable at all (`rescue StandardError` without `=> e`)
- ~20+ rescue blocks that capture the variable but return a default without logging
- Some of these are legitimate (logging code itself, `rescue LoadError` for optional requires, re-raises)

The existing `lint-patterns.yml` system already catches 18 anti-patterns via regex. This is the natural home for rescue enforcement rules.

## Proposed Solution

### Two-tier detection

**Tier 1: Single-line regex rules in `lint-patterns.yml`** (existing infrastructure)

These catch the most obvious violations:

| Rule ID | Pattern | What it catches | Severity |
|---------|---------|-----------------|----------|
| `rescue-bare-swallow` | `rescue\s*$` | Bare `rescue` with no class and no variable | warning |
| `rescue-no-capture` | `rescue\s+[\w:]+\s*$` | `rescue SomeError` without `=> e` — can't log what you don't capture | notice |

**Tier 2: Multi-line analysis via Ruby script** (new workflow job)

A small Ruby script (`scripts/check-rescue-logging.rb`) that parses each `.rb` file, finds rescue blocks that capture a variable (`=> e`), and verifies the body contains at least one of:

- `Legion::Logging.(debug|info|warn|error|fatal)` — direct singleton
- `log.(debug|info|warn|error|fatal)` — helper mixin
- `logger.(debug|info|warn|error|fatal)` — stdlib logger (edge cases)
- `runner_exception` — framework exception handler
- `raise` / `raise e` — re-raise (exception is not swallowed)

### Exclusions

| Path/Pattern | Reason |
|-------------|--------|
| `spec/**` | Test code, intentional rescue in specs |
| `legion-logging/lib/**` | Logging code itself — logging a failure in the logger causes recursion |
| Inline rescue (`expr rescue default`) | Single-expression fallbacks, not block rescues |

### New workflow job: `rescue-logging`

Added to `lint-patterns.yml` workflow as a fourth job alongside `gemfile-lock`, `helper-migration`, `constant-safety`, and `framework-conventions`.

### Severity model

- **lex-* repos**: All rescue-logging findings become `error` (same escalation as helper-migration)
- **legion-* repos**: Tier 1 rules use their declared severity; Tier 2 uses `warning`
- **LegionIO main repo**: `warning` (large existing codebase, gradual migration)

## Alternatives Considered

1. **Custom RuboCop cop** — More precise AST analysis, but requires a shared gem dependency across all repos. The regex + script approach works with the existing CI infrastructure and zero new dependencies.

2. **Just regex rules** — Single-line regex can't detect "captured variable but no log in body." Multi-line regex in grep is fragile for block structures. The Ruby script is 50-80 lines and handles nesting correctly.

3. **Ignore the problem** — Silent failures in an async job engine are a production incident waiting to happen. Even a warning-level annotation creates awareness.

## Trade-offs

- **False positives**: The Tier 2 script may flag rescue blocks where logging happens in a called method (e.g., `handle_error(e)` which internally logs). The `notice` severity mitigates this.
- **Existing violations**: There will be many existing findings. The `warning`/`notice` severity means CI won't break — this is a gradual migration, not a flag day.
- **Script maintenance**: The Ruby script is an additional artifact to maintain, but it's small and self-contained.
