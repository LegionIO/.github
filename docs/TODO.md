# LegionIO Project Tracker

Consolidated TODO for the entire LegionIO ecosystem.
Canonical source: https://github.com/LegionIO/.github/blob/main/docs/TODO.md

## Completed

- [x] Ruby 3.4 minimum across all 34 gemspecs
- [x] Git remotes consolidated to github.com/LegionIO
- [x] Gemspec URLs updated (Optum, Bitbucket, Atlassian -> LegionIO GitHub)
- [x] Optum corporate boilerplate removed (CODE_OF_CONDUCT, CONTRIBUTING, NOTICE, SECURITY, ICL, attribution, sourcehawk)
- [x] Optum email removed from gemspec contacts
- [x] Copyright updated to Esity in all LICENSE files
- [x] Author name normalized to Esity
- [x] LegionIO/README.md updated (Atlassian wiki links, /src/master/ paths)
- [x] sourcehawk-scan.yml CI workflows deleted
- [x] CLAUDE.md documentation created for all 34 repos
- [x] docs/protocol.md - wire protocol specification
- [x] docs/overview.md - core framework overview
- [x] CI: GitHub Actions `ci.yml` deployed to all 34 repos (rubocop + rspec on every push/PR)
- [x] `.rubocop.yml` updated to Ruby 3.4 + `frozen_string_literal: true` enabled across all 34 repos
- [x] Old CI deleted: bitbucket-pipelines.yml, .travis.yml, rubocop-analysis.yml, gems_push.yml (42 files)
- [x] All 34 README.md files rewritten (consistent format, Ruby 3.4, no JRuby, no stale boilerplate)
- [x] Fix stale `changelog_uri` paths in gemspecs (`/src/main/` -> `/blob/main/`)
- [x] Remove JRuby/MarchHare code paths (legion-transport, legion-settings, legion-data, LegionIO)
- [x] Update dependency version floors to Ruby 3.4-compatible versions (13 gemspecs across core gems + LEXs)
- [x] Fix `messsages` typo in legion-transport settings (triple s -> double s)
- [x] Fix legion-data to support SQLite, PostgreSQL, and MySQL (adapter-driven via settings)
- [x] Remove sleep hacks in `LegionIO/lib/legion/service.rb` (replaced with `Legion::Readiness`)
- [x] Remove TruffleRuby guard from service.rb
- [x] Structured JSON logging (`format: :json` in legion-logging)
- [x] Webhook hook system and Sinatra API (`Legion::API`, `Legion::Extensions::Hooks::Base`)
- [x] Add `frozen_string_literal: true` to all Ruby files (already done via rubocop -A)
- [x] Update Dockerfile (`ruby:3.4-alpine`, `--yjit` instead of `--jit`)
- [x] Event bus (`Legion::Events`) for in-process pub/sub
- [x] Transport abstraction layer (`Legion::Ingress`)
- [x] Configuration validation in legion-settings
- [x] Test coverage: legion-json (45 specs, 100% coverage)
- [x] Test coverage: legion-settings (107 specs, 94.04% coverage)
- [x] Test coverage: legion-cache (42 unit tests)
- [x] Test coverage: legion-crypt (52 specs)
- [x] Test coverage: LegionIO (55 specs, 43% coverage)

### Bug Fixes (all completed)

- [x] `app_id` and `correlation_id` now passed to `publish()` call; `app_id` method fixed
- [x] `correlation_id` derives from `parent_id` or `task_id` (links subtasks to parent)
- [x] Duplicate `LexRegister` removed (`messages/extension.rb` deleted)
- [x] Header values preserve native types (Integer, Float, Boolean); only others get `.to_s`
- [x] Task routing_key consolidated to `function` only (removed `function_name`/`name` fallbacks)
- [x] Base `message` method filters `ENVELOPE_KEYS` from payload
- [x] DLX exchanges auto-declared via `ensure_dlx` before queue creation
- [x] `NodeCrypt#queue_name` fixed: `'node.crypt'` (was `'node.status'`)
- [x] Priority reads from `@options[:priority]` then settings, falls back to 0
- [x] Per-message `encrypt:` option overrides global toggle

## In Progress

### Test Coverage

- [ ] Test coverage: core LEXs
  - [ ] lex-conditioner (all/any/fact/operator rule engine)
  - [ ] lex-transformer (ERB template rendering)
  - [ ] lex-scheduler (cron parsing, interval, distributed lock)
  - [ ] lex-node (node identity registration)
  - [ ] lex-tasker (task management)

### Standalone Client Pattern

- [ ] Document Client class convention in lex_gen template
- [ ] Refactor runner methods to accept config as keyword args (not read from `settings` directly)
- [ ] Add Client class to key LEXs: lex-http, lex-redis, lex-slack, lex-ssh
- [ ] Update remaining LEXs incrementally

### Settings Validation

- [ ] Dev mode: warn-but-continue instead of raise

### CLI

- [ ] Schedule management commands (`legion schedule list/add/remove`)

## Extension Build List

Extensions that need to be built or rebuilt with modern patterns.

### Priority

- [ ] Twilio — https://github.com/twilio/twilio-oai
- [ ] Elasticsearch — https://www.elastic.co/guide/en/elasticsearch/reference/current/rest-apis.html
- [ ] Pushover — https://pushover.net/api
- [ ] AWS S3 — https://docs.aws.amazon.com/AmazonS3/latest/API/Type_API_Reference.html
- [ ] Slack — https://api.slack.com/methods

### Backlog

- [ ] AWS Lambda — https://docs.aws.amazon.com/lambda/latest/dg/API_Reference.html
- [ ] Google Calendar — https://developers.google.com/calendar/api
- [ ] OpenWeatherMap — https://openweathermap.org/api
- [ ] Todoist — https://developer.todoist.com/rest/v2/#overview
- [ ] WLED — https://kno.wled.ge/interfaces/json-api/
- [ ] PiHole — https://docs.pi-hole.net/api/
- [ ] Home Assistant — https://developers.home-assistant.io/docs/api/rest/
- [ ] InfluxDB — https://docs.influxdata.com/influxdb/v2.0/api/
- [ ] PushBullet — https://pushbullet.com/api

### Completed Extensions

- [x] OpenAI — https://github.com/LegionIO/lex-openai

## Agentic AI LEX Extensions

Brain-modeled cognitive architecture (`esity-agentic-ai`).
Spec source: `esity-agentic-ai/spec/canonical-spec-v1.md` and `esity-agentic-ai/specs/`

### Phase 1: Core Cognitive Loop (MVP)

- [x] **lex-memory** — Memory trace system (7 trace types, power-law decay, 3-tier storage)
- [x] **lex-emotion** — 4-dimensional valence model, gut instinct, baseline adaptation
- [x] **lex-tick** — 11-phase tick loop, 3 modes (dormant/sentinel/active)
- [x] **lex-identity** — 6 identity dimensions, behavioral entropy, Ed25519 keys
- [x] **lex-consent** — 4-tier consent gradient with earned autonomy
- [x] **lex-prediction** — 4 reasoning modes, confidence model, causal chains
- [x] **lex-coldstart** — Firmware installation, imprint window, maturity milestones

### Phase 2: Conflict, Trust, and Governance

- [x] **lex-conflict** — Conflict detection, severity classification, response postures
- [x] **lex-trust** — 3 trust layers, domain-specific, asymmetric, velocity tracking
- [x] **lex-governance** — 4 governance layers, anti-capture mechanisms, council system
- [x] **lex-extinction** — 4 escalation levels, death protocol, cryptographic erasure

### Phase 3: Mesh and Swarm

- [x] **lex-mesh** — Federated hybrid topology, 3 protocols, membrane sovereignty
- [x] **lex-swarm** — Charter system, pipeline roles, queue-depth auto-scaling
- [x] **lex-swarm-github** — GitHub-specific finder/fixer/validator pipeline

### Phase 4: Private Core and Security

- [x] **lex-privatecore** — PII stripping, probing detection, 4-level key hierarchy

### Existing LEX Enhancements (for agentic support)

- [ ] **lex-conditioner** — consent tier evaluation, domain classification, conflict severity rules
- [ ] **lex-scheduler** — tick mode scheduling, mode transitions, emergency promotion
- [ ] **lex-github** — label management, comment threads, PR creation, webhook parsing
- [ ] **legion-llm** — embeddings, multi-model routing, shadow evaluation, structured output
- [ ] **legion-crypt** — Ed25519 keys, partition key hierarchy, cryptographic erasure, attestation
- [ ] **legion-data** — pgvector, memory trace migration, storage tiers, partition columns

### Rust FFI Integration

- [ ] **legion-ffi** — Rust bridge for decay computation, entropy, retrieval scoring, valence normalization

### Implementation Order

```
Phase 1 (MVP — single agent, single human):
  1. lex-memory, 2. lex-emotion, 3. lex-tick, 4. lex-identity,
  5. lex-consent, 6. lex-coldstart, 7. lex-prediction
  + legion-data pgvector, legion-llm embeddings, legion-crypt Ed25519

Phase 2 (multi-agent):
  8. lex-conflict, 9. lex-trust, 10. lex-mesh
  + lex-conditioner consent/conflict rules, lex-scheduler tick modes

Phase 3 (swarm — can run in parallel with Phase 1):
  11. lex-swarm, 12. lex-swarm-github
  + lex-github swarm enhancements, legion-llm structured output

Phase 4 (production hardening):
  13. lex-privatecore, 14. lex-governance, 15. lex-extinction
  + legion-crypt partition key/erasure, legion-ffi Rust bridge
```

## Core Components Reference

**Core Gems (9):** legion-json, legion-logging, legion-settings, legion-crypt, legion-transport, legion-cache, legion-data, legion-llm, legionio

**Core LEXs (5):** lex-conditioner, lex-transformer, lex-tasker, lex-node, lex-scheduler

**AI LEXs (3):** lex-claude, lex-openai, lex-gemini

**Agentic AI LEXs (15):** lex-memory, lex-emotion, lex-tick, lex-identity, lex-consent, lex-prediction, lex-coldstart, lex-conflict, lex-trust, lex-governance, lex-extinction, lex-mesh, lex-swarm, lex-swarm-github, lex-privatecore
