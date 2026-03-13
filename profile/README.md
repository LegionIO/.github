# LegionIO

**An extensible async job engine and brain-modeled agentic AI framework for Ruby.**

LegionIO schedules tasks, creates relationships between services, and runs them concurrently. What started as a job orchestration engine has evolved into a full framework for building autonomous AI agents with human-like cognitive architecture — memory, emotion, trust, prediction, consent, and multi-agent coordination.

## Brain-Modeled Agentic AI

LegionIO's agentic layer isn't a thin wrapper around an LLM. It's a cognitive architecture built from first principles:

| Extension | What It Does |
|-----------|-------------|
| **lex-tick** | Atomic cognitive processing cycle — 11 phases, 3 modes. The heartbeat of every agent. |
| **lex-memory** | Memory traces with consolidation, reinforcement, and natural decay. Agents forget what doesn't matter. |
| **lex-emotion** | Multi-dimensional emotional valence that influences decision-making. Not sentiment analysis — emergent affect. |
| **lex-prediction** | Forward-model prediction engine with 4 reasoning modes. Agents anticipate, not just react. |
| **lex-identity** | Models the human partner — behavioral entropy, interaction patterns, relationship context. |
| **lex-trust** | Domain-specific trust that's earned over time, not configured. Trust in "code review" is independent of trust in "deployment." |
| **lex-consent** | Four-tier consent gradient with earned autonomy. Agents gain independence as trust grows. |
| **lex-coldstart** | Imprint window and bootstrap calibration. How an agent learns who it's working with from zero. |
| **lex-conflict** | Conflict resolution with severity levels and postures. Agents handle disagreement, not just agreement. |
| **lex-governance** | Four-layer distributed governance protocol. Ethical guardrails that scale across agent swarms. |
| **lex-extinction** | Escalation and extinction protocol. Graceful degradation when things go wrong. |
| **lex-privatecore** | Privacy boundary enforcement with cryptographic erasure. Some things agents should never share. |

### Multi-Agent Coordination

| Extension | What It Does |
|-----------|-------------|
| **lex-swarm** | Swarm orchestration and charter system. Agents form teams, assign roles, and coordinate work. |
| **lex-swarm-github** | GitHub-specific swarm pipeline — finder/fixer/validator agents that collaborate on code. |
| **lex-mesh** | Agent-to-agent mesh communication protocol. Direct peer messaging between agents. |

### LLM Integration

| Component | What It Does |
|-----------|-------------|
| **legion-llm** | Core LLM layer — chat, embeddings, tool use, and agents via multiple providers (Bedrock, Anthropic, OpenAI, Gemini, Ollama). Vault-backed credential management. |
| **lex-claude** | Claude API integration (messages, models, batches, token counting) |
| **lex-openai** | OpenAI API integration (chat, images, audio, embeddings, files, moderations) |
| **lex-gemini** | Google Gemini API integration (content generation, embeddings, files, caching) |

## The Job Engine

The agentic AI runs on top of a battle-tested async job engine:

- **RabbitMQ** for task distribution (AMQP 0.9.1, priority queues, dead-letter exchanges)
- **Task chaining** with conditional evaluation and payload transformation between steps
- **Extension auto-discovery** — drop in a `lex-*` gem and it's live
- **Multiple actor types** — subscription, polling, interval, one-shot, loop
- **Cron + interval scheduling** with distributed locking
- **HashiCorp Vault** integration for secrets, dynamic credentials, and JWT
- **REST API** (Sinatra) and **MCP server** (Model Context Protocol) for AI agent integration
- **Unified CLI** (`legion`) with `--json` output on every command

## Architecture

```
                        ┌─────────────────────────────┐
                        │       LegionIO (core)       │
                        │   CLI / REST API / MCP Server│
                        └──────────┬──────────────────┘
                                   │
            ┌──────────┬───────────┼───────────┬──────────┐
            │          │           │           │          │
       legion-     legion-    legion-     legion-    legion-
       transport    crypt      data       cache      llm
       (RabbitMQ)  (Vault)   (Sequel)   (Redis)   (ruby_llm)
            │          │           │           │          │
            └──────────┴───────────┼───────────┴──────────┘
                                   │
                    ┌──────────────┼──────────────┐
                    │              │              │
              Built-in LEXs   AI/Cognitive    Service LEXs
              (tasker, node,  (memory, trust, (slack, redis,
               scheduler,     emotion, swarm,  http, ssh,
               conditioner)   prediction...)   s3, chef...)
```

## Repository Map

Use GitHub topics to navigate:

| Filter | What You Get |
|--------|-------------|
| [`legionio`](https://github.com/search?q=topic%3Alegionio+org%3ALegionIO&type=repositories) | Everything |
| [`legion-framework`](https://github.com/search?q=topic%3Allegion-framework+org%3ALegionIO&type=repositories) | Main framework gem |
| [`legion-core`](https://github.com/search?q=topic%3Allegion-core+org%3ALegionIO&type=repositories) | Core libraries (transport, crypt, data, cache, settings, logging, json, llm) |
| [`legion-builtin`](https://github.com/search?q=topic%3Allegion-builtin+org%3ALegionIO&type=repositories) | Built-in extensions (cognitive + operational) |
| [`legion-extension`](https://github.com/search?q=topic%3Allegion-extension+org%3ALegionIO&type=repositories) | All extensions |
| [`ai`](https://github.com/search?q=topic%3Aai+org%3ALegionIO&type=repositories) | AI/cognitive extensions + LLM integrations |
| [`multi-agent`](https://github.com/search?q=topic%3Amulti-agent+org%3ALegionIO&type=repositories) | Swarm and mesh coordination |
| [`smart-home`](https://github.com/search?q=topic%3Asmart-home+org%3ALegionIO&type=repositories) | Smart home integrations |
| [`notifications`](https://github.com/search?q=topic%3Anotifications+org%3ALegionIO&type=repositories) | Slack, SMS, email, push notifications |
| [`datastore`](https://github.com/search?q=topic%3Adatastore+org%3ALegionIO&type=repositories) | Redis, Elasticsearch, InfluxDB, S3, Memcached |
| [`monitoring`](https://github.com/search?q=topic%3Amonitoring+org%3ALegionIO&type=repositories) | Health, ping, PagerDuty |
| [`infrastructure`](https://github.com/search?q=topic%3Ainfrastructure+org%3ALegionIO&type=repositories) | SSH, HTTP, Chef, GitHub, Pi-hole |

## Quick Start

```bash
gem install legionio

# start the daemon
legion start

# list available extensions
legion lex list

# run a task
legion task run http.request.get url:https://example.com

# start the MCP server (for AI agents)
legion mcp
```

## Requirements

- Ruby >= 3.4
- RabbitMQ (AMQP 0.9.1)
- Optional: MySQL/PostgreSQL/SQLite, Redis/Memcached, HashiCorp Vault

## License

Core framework: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)
Extensions: [MIT](https://opensource.org/licenses/MIT)

---

**Author**: Matthew Iverson ([@Esity](https://github.com/Esity))
