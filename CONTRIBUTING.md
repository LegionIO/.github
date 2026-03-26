# Contributing to LegionIO

Thanks for your interest in contributing to LegionIO. This guide applies to all repositories in the [LegionIO](https://github.com/LegionIO) organization.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch (`git checkout -b feature/my-change`)
4. Make your changes
5. Push and open a pull request

## Requirements

- **Ruby >= 3.4**
- **Bundler** for dependency management
- **RabbitMQ** if working on transport or integration tests

## Development Workflow

All gems follow the same pattern:

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

### Running Tests

```bash
# full test suite
bundle exec rspec

# specific file or directory
bundle exec rspec spec/legion/transport/connection_spec.rb

# with output
bundle exec rspec --format documentation
```

### Code Style

We use RuboCop for consistent style. Run it before committing:

```bash
bundle exec rubocop

# auto-fix safe corrections
bundle exec rubocop -a
```

## Exception Handling

All rescue blocks in `lib/` code must log the exception or re-raise it. Silent rescues create invisible failure modes.

```ruby
# bad — exception is silently swallowed
rescue StandardError
  nil

# bad — variable captured but never logged
rescue StandardError => e
  default_value

# good — log via Helper mixin
rescue StandardError => e
  log.error("widget failed: #{e.message}")
  default_value

# good — log via direct singleton
rescue StandardError => e
  Legion::Logging.warn("fallback triggered: #{e.message}")
  default_value

# good — re-raise (exception is not swallowed)
rescue StandardError => e
  cleanup
  raise
```

This is enforced by CI via the `rescue-logging` lint check.

## Commit Messages

- Lowercase, imperative mood: `add vault namespace lookup`, `fix queue reconnection on timeout`
- Keep the first line under 72 characters
- Reference issues when relevant: `fix connection leak (#42)`

## Pull Request Guidelines

- **One concern per PR** — don't mix a bug fix with a feature
- **Tests required** — add or update specs for your changes
- **RuboCop clean** — no new linting violations
- **Description** — explain what changed and why, not just what files you touched

### PR Checklist

- [ ] Tests pass (`bundle exec rspec`)
- [ ] RuboCop passes (`bundle exec rubocop`)
- [ ] Commit messages follow conventions
- [ ] CHANGELOG.md updated (if applicable)

## Creating a New Extension (LEX)

Use the CLI to scaffold:

```bash
legion lex create my_extension
```

This generates the standard directory structure with runners, actors, transport, specs, and CI config. Extensions are Ruby gems named `lex-*` that are auto-discovered by the framework.

### Extension Guidelines

- Runner methods should accept config as keyword args (not read from global settings directly)
- Provide a `Client` class for standalone use without the full framework
- Include specs that can run without RabbitMQ or a database
- Use `faraday` for HTTP-based service integrations

### Extension Categories

| Directory | What Goes Here |
|-----------|---------------|
| `extensions-core/` | Framework plumbing (task management, scheduling, health) |
| `extensions-agentic/` | Brain-modeled cognitive architecture |
| `extensions-ai/` | LLM provider integrations |
| `extensions/` | Common service integrations (HTTP, Redis, S3, GitHub) |
| `extensions-other/` | Additional service integrations |

## Repository Structure

Each gem follows a consistent layout:

```
lex-example/
├── lib/legion/extensions/example/
│   ├── runners/         # Business logic (callable functions)
│   ├── actors/          # Execution modes (subscription, polling, etc.)
│   ├── helpers/         # Shared utilities, client connections
│   └── transport/       # AMQP exchanges, queues, messages
├── spec/                # RSpec tests
├── CLAUDE.md            # AI-readable documentation
├── CHANGELOG.md         # Version history
├── README.md            # Human-readable documentation
└── lex-example.gemspec  # Gem specification
```

## Reporting Issues

- Use the issue templates provided
- Include Ruby version, gem version, and relevant config
- For bugs: steps to reproduce, expected vs actual behavior
- For features: describe the use case, not just the solution

## Security

See [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## License

By contributing, you agree that your contributions will be licensed under the same license as the project:
- Core framework and libraries: [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0)
- Extensions: [MIT](https://opensource.org/licenses/MIT)
