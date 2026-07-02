<div align="center">

# LegionIO

### LLM routing and context curation in one open-source proxy, built on a distributed Ruby job engine.

[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%203.4-red)](https://www.ruby-lang.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Gem](https://img.shields.io/gem/v/legionio.svg)](https://rubygems.org/gems/legionio)

**[legionio.dev](https://legionio.dev)** | [Main README](https://github.com/LegionIO/LegionIO) | [Getting Started](https://legionio.dev/getting-started/) | [Discussions](https://github.com/LegionIO/LegionIO/discussions)

```bash
brew tap LegionIO/tap && brew install legionio
LEGION_MODE=lite legion start   # zero infrastructure, five-minute eval
```

</div>

---

LegionIO is a set of independently composable Ruby gems. The core is a distributed
async job engine; on top of it sit an LLM gateway, an MCP server, RBAC, an audit
ledger, and an explicitly experimental cognitive layer. Install any subset;
dependencies between layers are declared in gemspecs, not documentation. There are no
paid tiers and no feature gates anywhere in the ecosystem.

## The flagship: [legion-llm](https://github.com/LegionIO/legion-llm)

A proxy between your AI clients and any model backend that does two jobs most tools
split between them:

**Routing.** Models are classified into five tiers —
[local(0) → direct(1) → fleet(2) → cloud(3) → frontier(4)](https://github.com/LegionIO/legion-llm/blob/main/lib/legion/llm/router.rb)
— and requests try the cheapest capable tier first, escalating on failure or
capability mismatch. Per-provider [circuit breakers](https://github.com/LegionIO/legion-llm/blob/main/lib/legion/llm/router/health_tracker.rb)
handle unhealthy backends, and a provider dying mid-stream fails over with the client
stream continuing.

**Curation.** After each turn, six deterministic strategies in the
[Curator](https://github.com/LegionIO/legion-llm/blob/main/lib/legion/llm/context/curator.rb)
shrink accumulated conversation history. Production results across all requests,
including where it does nothing:

| Conversation length | 1 turn | 2–3 | 4–5 | 6–9 | 10–19 | 20–49 | 50+ |
|---|---|---|---|---|---|---|---|
| Reduction vs. naive resend | -0.1% | 9.6% | 13.3% | 23.6% | 54.3% | 72.8% | **97.7%** |

Single-shot workloads gain nothing; long agent sessions stop ballooning. Full
methodology and caveats:
[curation-production-metrics.md](https://github.com/LegionIO/legion-llm/blob/main/docs/curation-production-metrics.md).

Every number above is a query over
[lex-llm-ledger](https://github.com/LegionIO/lex-llm-ledger) — the audit ledger
that records each request for finance and compliance. Any deployment that installs
it gets the same measurability; we are not asking you to trust our benchmarks, we
ship the instrument that produced them.

Nine provider adapters (Anthropic, OpenAI, Bedrock, Gemini, Vertex, Azure Foundry,
Ollama, vLLM, MLX) plug into the [lex-llm](https://github.com/LegionIO/lex-llm)
contract layer. Install only the ones you use.

## The engine underneath: [LegionIO](https://github.com/LegionIO/LegionIO)

Task chains with conditions and transformations, eight actor types, distributed cron
scheduling, and a disk spool that rides out broker outages. RabbitMQ-backed in full
mode; `LEGION_MODE=lite` runs everything in-process with zero external services.
The job engine predates the AI layers and works without any of them.

## 119 extension gems, and every runner is a tool

Integrations are separate `lex-*` gems — checking legion-llm for a Teams integration
will correctly find nothing, because it lives in
[lex-microsoft_teams](https://github.com/LegionIO/lex-microsoft_teams) (25 runners:
chats, channels, meetings, transcripts, presence, files, adaptive cards). The
authoritative list is the
**[capability catalog](https://github.com/LegionIO/.github/blob/main/capabilities.md)** —
774 runners exposing 4,590 functions across the extension gems, generated from source
on every release.

When traffic routes through LegionIO, exposed runner functions automatically become
tools: your client sees a server-side tool, LegionIO executes it directly and returns
the result on the wire — no client round-trip, no token overhead for tool plumbing.
Discovery is contextual: runners declare trigger words, so mentioning a Slack thread
or a Teams meeting injects those tool definitions into that request. Mechanism:
[function_discovery.rb](https://github.com/LegionIO/legion-mcp/blob/main/lib/legion/mcp/function_discovery.rb).

Highlights beyond the LLM stack: lex-slack, lex-github, lex-splunk, lex-jira,
lex-pagerduty, lex-service_now, lex-vault, lex-consul, lex-nomad, lex-ssh,
lex-postgres, lex-redis, lex-elasticsearch, lex-prometheus, lex-home_assistant,
lex-apollo and lex-knowledge (RAG activation), and lex-mesh (cross-node agent
coordination).

## The fleet tier: idle workstations as inference capacity

The router's `fleet` tier (rank 2) dispatches inference over AMQP to any LegionIO
node running a local model — Apple-silicon machines via
[lex-llm-mlx](https://github.com/LegionIO/lex-llm-mlx), or
[lex-llm-ollama](https://github.com/LegionIO/lex-llm-ollama). Requests carry signed
work tokens and validated envelopes, route per-lane, and return over dedicated fleet
exchanges. Idle workstation GPUs become a shared inference tier that sits between
local and cloud in the cost ladder. Implementation:
[fleet.rb](https://github.com/LegionIO/legion-llm/blob/main/lib/legion/llm/fleet.rb)
and the [lex-llm fleet protocol](https://github.com/LegionIO/lex-llm/tree/main/lib/legion/extensions/llm/fleet).

## The Fleet Pipeline: issues in, validated PRs out

```
lex-assessor → lex-planner → lex-developer → lex-validator → ship
                                                   ↓
                                        (rejected) → lex-developer (feedback loop)
```

[lex-assessor](https://github.com/LegionIO/lex-assessor) deduplicates work items
atomically (SHA256 fingerprint claimed via Redis SETNX) and classifies them with LLM
structured output; [lex-planner](https://github.com/LegionIO/lex-planner) decomposes
them into implementation plans with repository context;
[lex-developer](https://github.com/LegionIO/lex-developer) generates code, commits,
and opens a draft PR, incorporating feedback when rejected;
[lex-validator](https://github.com/LegionIO/lex-validator) runs a four-stage gauntlet
— tests, lint, security scan, and adversarial multi-model LLM review — before the
ship stage marks the PR ready. The pipeline is
[integration-tested end to end](https://github.com/LegionIO/LegionIO/pull/138); it is
early, and first labeled production runs are the next milestone.

## The experimental part, labeled as such

Sixteen `lex-agentic-*` gems (369 actor/runner modules) explore one research
question: does a job engine improve when successful task-routes strengthen and unused
ones decay? A [16-phase tick cycle](https://github.com/LegionIO/lex-tick/blob/main/lib/legion/extensions/tick/helpers/constants.rb)
schedules the work in budgeted modes; a 10-phase idle cycle consolidates what the
deployment learns and feeds it back into RAG retrieval. Mechanically, each module is
a scheduled job adjusting persistent state — we say that plainly, because the
interesting part is the adaptive routing, not the vocabulary. None of it exists in
your deployment unless you install it.

## Verify before you trust

Every number above is reproducible from public source; the
[main README](https://github.com/LegionIO/LegionIO#verify-the-claims-yourself) has
copy-pasteable one-liners. Engineering docs — router design, the debugging
methodology the routing layer is held to — are public in
[legion-llm/docs](https://github.com/LegionIO/legion-llm/tree/main/docs/work/planning).
An AI-assistant-oriented fact sheet lives at
[legionio.dev/llms.txt](https://legionio.dev/llms.txt).

Project status, honestly: built primarily by one engineer with a disciplined process
(PRs, CI, conventional commits, RSpec and RuboCop green before merge). The org dates
to 2018; the AI platform is a 2025–2026 rebuild, which is why most repos are young.
It runs production workloads daily. Read the source before betting on it. It
originated under [Optum Open Source](https://github.com/Optum/LegionIO), which
remains the upstream this org merges back to — the provenance behind the governance
features.

## Where to look before you judge

Copy claims are cheap; these artifacts settle questions, in reading order:

- **5 minutes:** the [main README](https://github.com/LegionIO/LegionIO) — it
  pre-answers the standard audit, with a reproduce-command for every number.
- **30 minutes:** [router.rb](https://github.com/LegionIO/legion-llm/blob/main/lib/legion/llm/router.rb),
  [curator.rb](https://github.com/LegionIO/legion-llm/blob/main/lib/legion/llm/context/curator.rb),
  the [production metrics](https://github.com/LegionIO/legion-llm/blob/main/docs/curation-production-metrics.md),
  and the [capability catalog](https://github.com/LegionIO/.github/blob/main/capabilities.md).
- **Full audit:** the [engineering docs](https://github.com/LegionIO/legion-llm/tree/main/docs/work/planning)
  (router design, debugging methodology), any runner file, any spec/ directory.

Evaluating with an AI assistant? Point it at
[legionio.dev/llms.txt](https://legionio.dev/llms.txt) — it lists the common false
conclusions about this project and the file that disproves each.

## The index

Too much to read is the point: every row below is a real repo. Core libraries first,
then every published extension, generated from source.

### Core libraries

| Repo | What it owns |
|------|-------------|
| [LegionIO](https://github.com/LegionIO/LegionIO) | The primary gem: daemon lifecycle, CLI, REST API, extension loading |
| [legion-llm](https://github.com/LegionIO/legion-llm) | LLM gateway: tiered routing, mid-stream failover, context curation |
| [legion-gaia](https://github.com/LegionIO/legion-gaia) | Cognitive coordination: tick scheduling over the agentic extensions (experimental) |
| [legion-apollo](https://github.com/LegionIO/legion-apollo) | Knowledge store: pgvector-backed RAG retrieval with confidence decay |
| [legion-data](https://github.com/LegionIO/legion-data) | Persistence over SQLite / PostgreSQL / MySQL via Sequel |
| [legion-transport](https://github.com/LegionIO/legion-transport) | Messaging: RabbitMQ AMQP plus the in-process lite adapter |
| [legion-cache](https://github.com/LegionIO/legion-cache) | Caching: Redis / Memcached plus the in-memory lite adapter |
| [legion-crypt](https://github.com/LegionIO/legion-crypt) | Secrets and encryption: Vault integration, AES-256, JWT |
| [legion-rbac](https://github.com/LegionIO/legion-rbac) | Access control: Vault-style flat policies |
| [legion-mcp](https://github.com/LegionIO/legion-mcp) | MCP server and client; runtime tool discovery from installed extensions |
| [legion-settings](https://github.com/LegionIO/legion-settings) | Layered configuration and secret resolution (vault://, env://) |
| [legion-logging](https://github.com/LegionIO/legion-logging) | Structured logging used across every gem |
| [legion-json](https://github.com/LegionIO/legion-json) | JSON handling (symbol keys everywhere) |
| [legion-tty](https://github.com/LegionIO/legion-tty) | Terminal UI components |

### Extensions

<!-- CATALOG:BEGIN -->

### AI & LLM (11)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-llm](https://github.com/LegionIO/lex-llm) | Shared LegionIO LLM provider framework |  |  |
| [lex-llm-anthropic](https://github.com/LegionIO/lex-llm-anthropic) | LegionIO LLM Anthropic provider extension | 1 | 1 |
| [lex-llm-azure-foundry](https://github.com/LegionIO/lex-llm-azure-foundry) | LegionIO LLM Azure AI Foundry provider extension | 1 | 1 |
| [lex-llm-bedrock](https://github.com/LegionIO/lex-llm-bedrock) | LegionIO LLM Amazon Bedrock provider extension | 1 | 2 |
| [lex-llm-gemini](https://github.com/LegionIO/lex-llm-gemini) | LegionIO LLM Gemini provider extension | 1 | 1 |
| [lex-llm-ledger](https://github.com/LegionIO/lex-llm-ledger) |  | 17 | 49 |
| [lex-llm-mlx](https://github.com/LegionIO/lex-llm-mlx) | LegionIO LLM MLX provider extension | 1 | 1 |
| [lex-llm-ollama](https://github.com/LegionIO/lex-llm-ollama) | LegionIO LLM Ollama provider extension | 1 | 1 |
| [lex-llm-openai](https://github.com/LegionIO/lex-llm-openai) | LegionIO LLM OpenAI provider extension | 1 | 2 |
| [lex-llm-vertex](https://github.com/LegionIO/lex-llm-vertex) | LegionIO LLM Google Cloud Vertex AI provider extension | 1 | 1 |
| [lex-llm-vllm](https://github.com/LegionIO/lex-llm-vllm) | LegionIO LLM vLLM provider extension | 1 | 2 |

### Agentic (Experimental) (16)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-agentic-affect](https://github.com/LegionIO/lex-agentic-affect) |  | 18 | 135 |
| [lex-agentic-attention](https://github.com/LegionIO/lex-agentic-attention) |  | 24 | 204 |
| [lex-agentic-defense](https://github.com/LegionIO/lex-agentic-defense) |  | 15 | 127 |
| [lex-agentic-executive](https://github.com/LegionIO/lex-agentic-executive) |  | 23 | 239 |
| [lex-agentic-homeostasis](https://github.com/LegionIO/lex-agentic-homeostasis) |  | 20 | 154 |
| [lex-agentic-inference](https://github.com/LegionIO/lex-agentic-inference) |  | 27 | 255 |
| [lex-agentic-integration](https://github.com/LegionIO/lex-agentic-integration) |  | 17 | 149 |
| [lex-agentic-language](https://github.com/LegionIO/lex-agentic-language) |  | 9 | 82 |
| [lex-agentic-learning](https://github.com/LegionIO/lex-agentic-learning) |  | 15 | 125 |
| [lex-agentic-memory](https://github.com/LegionIO/lex-agentic-memory) |  | 22 | 175 |
| [lex-agentic-self](https://github.com/LegionIO/lex-agentic-self) |  | 19 | 163 |
| [lex-agentic-social](https://github.com/LegionIO/lex-agentic-social) |  | 22 | 168 |
| [lex-extinction](https://github.com/LegionIO/lex-extinction) | Agent lifecycle termination protocol for LegionIO | 1 | 7 |
| [lex-mind-growth](https://github.com/LegionIO/lex-mind-growth) |  | 18 | 85 |
| [lex-synapse](https://github.com/LegionIO/lex-synapse) | Cognitive routing layer for LegionIO task chains | 13 | 23 |
| [lex-tick](https://github.com/LegionIO/lex-tick) |  | 1 | 5 |

### Code Workflow (5)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-assessor](https://github.com/LegionIO/lex-assessor) | Fleet pipeline intake for LegionIO | 1 | 2 |
| [lex-developer](https://github.com/LegionIO/lex-developer) | Legion::Extensions::Developer | 3 | 4 |
| [lex-factory](https://github.com/LegionIO/lex-factory) | Spec-to-code autonomous pipeline for LegionIO | 1 | 2 |
| [lex-planner](https://github.com/LegionIO/lex-planner) | Legion::Extensions::Planner | 1 | 2 |
| [lex-validator](https://github.com/LegionIO/lex-validator) | Legion::Extensions::Validator | 1 | 1 |

### Core & Services (40)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-acp](https://github.com/LegionIO/lex-acp) | ACP agent protocol adapter for LegionIO | 2 | 12 |
| [lex-adapter](https://github.com/LegionIO/lex-adapter) | External agent adapter abstraction for LegionIO | 1 | 3 |
| [lex-apollo](https://github.com/LegionIO/lex-apollo) | Shared knowledge store for GAIA cognitive mesh | 6 | 57 |
| [lex-audit](https://github.com/LegionIO/lex-audit) | Legion::Extensions::Audit | 2 | 7 |
| [lex-autofix](https://github.com/LegionIO/lex-autofix) | Autonomous error fix agent for LegionIO | 5 | 12 |
| [lex-codegen](https://github.com/LegionIO/lex-codegen) | Legion::Extensions::Codegen | 6 | 17 |
| [lex-coldstart](https://github.com/LegionIO/lex-coldstart) |  | 2 | 8 |
| [lex-conditioner](https://github.com/LegionIO/lex-conditioner) | Conditional rule engine for LegionIO task chains | 4 | 5 |
| [lex-cost-scanner](https://github.com/LegionIO/lex-cost-scanner) | Cloud cost optimization scanner for LegionIO | 2 | 6 |
| [lex-dataset](https://github.com/LegionIO/lex-dataset) | Versioned dataset management for LegionIO | 3 | 10 |
| [lex-detect](https://github.com/LegionIO/lex-detect) |  | 2 | 2 |
| [lex-eval](https://github.com/LegionIO/lex-eval) | LLM output evaluation framework for LegionIO | 5 | 15 |
| [lex-exec](https://github.com/LegionIO/lex-exec) |  | 4 | 29 |
| [lex-github](https://github.com/LegionIO/lex-github) |  | 25 | 138 |
| [lex-governance](https://github.com/LegionIO/lex-governance) |  | 1 | 7 |
| [lex-health](https://github.com/LegionIO/lex-health) | Legion::Extensions::Health | 2 | 4 |
| [lex-http](https://github.com/LegionIO/lex-http) |  | 1 | 8 |
| [lex-knowledge](https://github.com/LegionIO/lex-knowledge) | Document corpus ingestion and knowledge query pipeline for LegionIO | 5 | 70 |
| [lex-lex](https://github.com/LegionIO/lex-lex) | Legion Extension Registry | 5 | 16 |
| [lex-log](https://github.com/LegionIO/lex-log) | Used to generate logs within the Legion framework | 1 | 2 |
| [lex-mesh](https://github.com/LegionIO/lex-mesh) |  | 4 | 25 |
| [lex-metering](https://github.com/LegionIO/lex-metering) | Legion::Extensions::Metering | 3 | 8 |
| [lex-microsoft_teams](https://github.com/LegionIO/lex-microsoft_teams) |  | 25 | 104 |
| [lex-nautobot](https://github.com/LegionIO/lex-nautobot) |  | 10 | 236 |
| [lex-neo4j](https://github.com/LegionIO/lex-neo4j) |  | 7 | 48 |
| [lex-node](https://github.com/LegionIO/lex-node) | Does Legion Node things | 3 | 18 |
| [lex-onboard](https://github.com/LegionIO/lex-onboard) |  | 2 | 3 |
| [lex-pilot-knowledge-assist](https://github.com/LegionIO/lex-pilot-knowledge-assist) |  | 3 | 4 |
| [lex-ping](https://github.com/LegionIO/lex-ping) |  | 3 | 3 |
| [lex-privatecore](https://github.com/LegionIO/lex-privatecore) |  | 2 | 8 |
| [lex-prompt](https://github.com/LegionIO/lex-prompt) | Versioned prompt management for LegionIO | 1 | 6 |
| [lex-react](https://github.com/LegionIO/lex-react) | Reaction engine for LegionIO | 1 | 3 |
| [lex-s3](https://github.com/LegionIO/lex-s3) |  | 2 | 10 |
| [lex-scheduler](https://github.com/LegionIO/lex-scheduler) |  | 4 | 20 |
| [lex-splunk](https://github.com/LegionIO/lex-splunk) |  | 49 | 177 |
| [lex-tasker](https://github.com/LegionIO/lex-tasker) |  | 5 | 24 |
| [lex-telemetry](https://github.com/LegionIO/lex-telemetry) | Legion::Extensions::Telemetry | 1 | 18 |
| [lex-tfe](https://github.com/LegionIO/lex-tfe) |  | 10 | 42 |
| [lex-transformer](https://github.com/LegionIO/lex-transformer) | Payload transformation engine for LegionIO task chains | 1 | 6 |
| [lex-webhook](https://github.com/LegionIO/lex-webhook) | Legion::Extensions::Webhook | 3 | 6 |

### Identity (7)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-identity-entra](https://github.com/LegionIO/lex-identity-entra) |  | 5 | 17 |
| [lex-identity-github](https://github.com/LegionIO/lex-identity-github) |  |  |  |
| [lex-identity-kerberos](https://github.com/LegionIO/lex-identity-kerberos) |  |  |  |
| [lex-identity-ldap](https://github.com/LegionIO/lex-identity-ldap) |  |  |  |
| [lex-identity-ledger](https://github.com/LegionIO/lex-identity-ledger) |  | 3 | 3 |
| [lex-identity-system](https://github.com/LegionIO/lex-identity-system) |  |  |  |
| [lex-kerberos](https://github.com/LegionIO/lex-kerberos) |  | 1 | 2 |

### Service Integrations (22)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-arize](https://github.com/LegionIO/lex-arize) |  | 12 | 70 |
| [lex-cloudflare](https://github.com/LegionIO/lex-cloudflare) |  | 29 | 137 |
| [lex-consul](https://github.com/LegionIO/lex-consul) |  | 8 | 37 |
| [lex-elasticsearch](https://github.com/LegionIO/lex-elasticsearch) |  | 3 | 11 |
| [lex-esphome](https://github.com/LegionIO/lex-esphome) |  | 17 | 53 |
| [lex-home_assistant](https://github.com/LegionIO/lex-home_assistant) |  | 11 | 22 |
| [lex-jfrog](https://github.com/LegionIO/lex-jfrog) |  | 5 | 37 |
| [lex-jira](https://github.com/LegionIO/lex-jira) |  | 27 | 129 |
| [lex-lakera](https://github.com/LegionIO/lex-lakera) |  | 4 | 15 |
| [lex-memcached](https://github.com/LegionIO/lex-memcached) |  | 2 | 11 |
| [lex-mongodb](https://github.com/LegionIO/lex-mongodb) |  | 2 | 12 |
| [lex-nomad](https://github.com/LegionIO/lex-nomad) |  | 10 | 62 |
| [lex-pagerduty](https://github.com/LegionIO/lex-pagerduty) |  | 14 | 71 |
| [lex-postgres](https://github.com/LegionIO/lex-postgres) |  | 2 | 5 |
| [lex-prometheus](https://github.com/LegionIO/lex-prometheus) |  | 2 | 7 |
| [lex-redis](https://github.com/LegionIO/lex-redis) |  | 2 | 14 |
| [lex-service_now](https://github.com/LegionIO/lex-service_now) |  | 66 | 346 |
| [lex-slack](https://github.com/LegionIO/lex-slack) |  | 12 | 73 |
| [lex-smtp](https://github.com/LegionIO/lex-smtp) |  | 1 | 1 |
| [lex-ssh](https://github.com/LegionIO/lex-ssh) |  | 2 | 4 |
| [lex-vault](https://github.com/LegionIO/lex-vault) |  | 7 | 69 |
| [lex-velociraptor](https://github.com/LegionIO/lex-velociraptor) |  | 3 | 10 |

### Skills (1)

| Repo | Summary | Runners | Functions |
|------|---------|---------|-----------|
| [lex-skill-superpowers](https://github.com/LegionIO/lex-skill-superpowers) | Superpowers skill set for Legion LLM |  |  |

<!-- CATALOG:END -->

## License

Core framework: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) | Extensions: [MIT](https://opensource.org/licenses/MIT)

<div align="center">

**Built by [Matthew Iverson](https://github.com/Esity)**

</div>
