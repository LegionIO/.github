# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest release | Yes |
| Previous minor | Security fixes only |
| Older | No |

This policy applies to all gems in the [LegionIO](https://github.com/LegionIO) organization.

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Instead, please report vulnerabilities through one of these channels:

1. **GitHub Security Advisories** (preferred): Use the "Report a vulnerability" button on the Security tab of the affected repository
2. **Email**: Send details to matthewdiverson@gmail.com

### What to Include

- Affected gem(s) and version(s)
- Description of the vulnerability
- Steps to reproduce or proof of concept
- Impact assessment (what an attacker could do)

### Response Timeline

- **Acknowledgment**: Within 48 hours
- **Assessment**: Within 1 week
- **Fix**: Depends on severity
  - Critical: Patch release within 72 hours
  - High: Patch release within 1 week
  - Medium/Low: Included in next scheduled release

### After Reporting

- You'll receive confirmation that the report was received
- We'll work with you to understand the issue
- We'll coordinate disclosure timing with you
- We'll credit you in the advisory (unless you prefer anonymity)

## Security Considerations

### Vault Integration (legion-crypt)

- Dynamic credentials with short TTLs (30 min default, 4 hr max)
- JWT support (HS256/RS256) for inter-node and API authentication
- Cluster secrets distributed via encrypted AMQP messages

### Transport Security (legion-transport)

- TLS support for RabbitMQ connections
- Message encryption available via legion-crypt
- Vault-backed credential retrieval for RabbitMQ

### API Security (LegionIO)

- REST API auth middleware is in development (JWT + API keys)
- Config endpoints auto-redact sensitive values (password, token, secret, key)
- Read-only guards on security-critical settings sections

### Extension Security

- Extensions are loaded from installed gems only (no arbitrary code execution)
- Runner functions execute in managed thread pools with supervision
- Database operations use parameterized queries via Sequel ORM
