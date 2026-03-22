# LegionIO Governance

## Overview

LegionIO is an open-source async job engine and extension ecosystem for Ruby. It is currently solo-maintained by [@Esity](https://github.com/Esity) (Matthew Iverson), who acts as BDFL (Benevolent Dictator for Life) while the project grows toward a collaborative core team model.

This document describes how decisions are made, how contributors can grow their involvement, and how the project is run.

---

## Project Leadership

### Current State: Solo BDFL

All architectural decisions, release approvals, and direction-setting are currently owned by @Esity. This is honest, not a limitation — a single coherent vision is appropriate at this stage.

### Path to Core Team

As the contributor community matures, trusted contributors with deep architectural understanding will be invited to join a core team. Core team members share responsibility for direction, review, and releases alongside the BDFL.

There is no fixed timeline. This happens when it makes sense, not on a schedule.

---

## Decision Making

### Everyday Decisions

Routine decisions — bug fixes, minor features, compatibility improvements — are made by the maintainer or reviewer approving a pull request.

### Architectural Decisions

Significant changes to core architecture, extension protocols, transport contracts, or the public API follow this process:

1. Open a discussion in [GitHub Discussions](https://github.com/LegionIO/LegionIO/discussions) under the **Architecture** category.
2. Write a design doc in `docs/plans/` following the existing naming convention (`YYYY-MM-DD-topic-design.md`).
3. Allow at least one week for community input before a decision is finalized.
4. The BDFL (or core team, once formed) makes the final call.

Design docs are the record of intent. They are not just process — they are how the project tracks why decisions were made.

### Reversing Decisions

Decisions can be revisited. Open a new discussion referencing the original. Reversals require the same process as original decisions.

---

## Contribution Path

There are three levels of involvement:

### Contributor

Anyone who submits a pull request. Contributors are welcome at any experience level. See [CONTRIBUTING.md](CONTRIBUTING.md) for the technical requirements (specs, RuboCop, CHANGELOG).

### Committer

A contributor who has demonstrated consistent quality contributions over time — clean code, good judgment in reviews, understanding of the extension system, and reliable follow-through. Committers may be invited to review and merge pull requests in areas they know well.

Committer status is granted by invitation, not application. There is no checklist. It reflects earned trust.

### Core Team

Core team members have deep architectural understanding of LegionIO, have contributed across multiple subsystems, and have demonstrated trustworthy judgment over an extended period. Core team members co-own project direction alongside the BDFL.

Core team membership is rare and meaningful. It will not be handed out to meet a quota.

---

## Extension Ownership

LegionIO's extension ecosystem (LEX) is built around the principle that extension authors own their gems.

- Extension authors are the primary decision-makers for their `lex-*` gems.
- The core team reviews extensions for quality, API compatibility with the framework, and protocol compliance before inclusion in the official ecosystem.
- Extension authors are expected to maintain their gems, respond to issues, and follow the pre-push pipeline.
- If an extension is abandoned, the core team may adopt it, archive it, or remove it from the official ecosystem listing.

---

## Release Process

LegionIO follows [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH).

- **PATCH**: Bug fixes, internal refactors with no public API change.
- **MINOR**: New features, new runners/actors, backward-compatible additions.
- **MAJOR**: Breaking changes to public API, transport contracts, or extension protocols.

All releases must:

1. Pass the full spec suite (`bundle exec rspec`) with zero failures.
2. Pass RuboCop (`bundle exec rubocop`) with zero offenses.
3. Include a `CHANGELOG.md` entry following [Keep a Changelog](https://keepachangelog.com/) format.
4. Have a version bump in `version.rb`.

Releases are cut by the BDFL or a delegated core team member.

---

## Communication

**Async (primary)**: [GitHub Discussions](https://github.com/LegionIO/LegionIO/discussions) — architecture, feature proposals, questions, announcements.

**Real-time**: Slack — for quick questions, pairing, and informal discussion. Join via the link in the README.

Issues are for bugs and specific feature requests with enough detail to act on. Vague ideas belong in Discussions first.

---

## Code of Conduct

All contributors and participants are expected to follow the project's [Code of Conduct](CODE_OF_CONDUCT.md). This applies in all project spaces: GitHub, Discussions, Slack, and anywhere else LegionIO community interaction occurs.

---

## Amendment

This document can be changed via pull request. Significant changes (role definitions, decision processes) should go through a GitHub Discussion first.

---

*Last updated: 2026-03-21*
