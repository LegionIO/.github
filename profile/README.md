<div align="center">

# LegionIO

### LLM routing and context curation in one open-source proxy, built on a distributed Ruby job engine.

[![Ruby](https://img.shields.io/badge/Ruby-%3E%3D%203.4-red)](https://www.ruby-lang.org)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)
[![Gem](https://img.shields.io/gem/v/legionio.svg)](https://rubygems.org/gems/legionio)

**[legionio.dev](https://legionio.dev)** | [Main README](https://github.com/LegionIO/LegionIO) | [Getting Started](https://legionio.dev/getting-started/) | [Discussions](https://github.com/LegionIO/docs/discussions)

```bash
gem install legionio
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
**[capability catalog](https://github.com/LegionIO/docs/blob/main/capabilities.md)** —
845 runners exposing 4,840 functions across the extension gems, generated from source
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
It runs production workloads daily. Read the source before betting on it.

## Navigate the ecosystem

| Filter | What you get |
|--------|-------------|
| [`legion-core`](https://github.com/search?q=topic%3Alegion-core+org%3ALegionIO&type=repositories) | Core libraries (transport, crypt, data, cache, settings, logging, json, llm, gaia) |
| [`ai`](https://github.com/search?q=topic%3Aai+org%3ALegionIO&type=repositories) | LLM gateway, provider adapters, agentic extensions |
| [`legion-extension`](https://github.com/search?q=topic%3Alegion-extension+org%3ALegionIO&type=repositories) | All extensions |
| [`datastore`](https://github.com/search?q=topic%3Adatastore+org%3ALegionIO&type=repositories) | Redis, Elasticsearch, InfluxDB, S3, Memcached |
| [`notifications`](https://github.com/search?q=topic%3Anotifications+org%3ALegionIO&type=repositories) | Slack, SMS, email, push |
| [`infrastructure`](https://github.com/search?q=topic%3Ainfrastructure+org%3ALegionIO&type=repositories) | SSH, HTTP, Chef, GitHub, TFE |
| [`monitoring`](https://github.com/search?q=topic%3Amonitoring+org%3ALegionIO&type=repositories) | Health, ping, PagerDuty |

## License

Core framework: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0) | Extensions: [MIT](https://opensource.org/licenses/MIT)

<div align="center">

**Built by [Matthew Iverson](https://github.com/Esity)**

</div>
