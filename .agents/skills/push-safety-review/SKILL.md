---
name: push-safety-review
description: Review this repository before committing or pushing to catch accidental files, secrets, local-only state, and risky Docker or database exposure.
---

# Push Safety Review

Use this skill when the user asks whether the current commit, branch, or push state is safe, or asks for a pre-push, release, or accidental-file review in this repository.

Focus on risks that matter for this local learning TODO app:

- Accidental files: `.env`, local notes, virtualenvs, caches, logs, database files, private keys, package caches, and large binary files.
- Secrets: API keys, GitHub tokens, private keys, real database credentials, and production-looking values. Treat `.env.example` placeholder values as acceptable when they are clearly non-secret.
- Docker exposure: host-published ports, especially database ports. For local-only services, prefer loopback bindings such as `127.0.0.1:5433:5432`.
- Documentation drift: README and Makefile commands should match `docker-compose.yml` service names, project name, ports, and app URLs.
- Scope drift: keep the app simple and local-development oriented unless the user explicitly asks for production hardening.

When reviewing, inspect the relevant Git state first:

```bash
git status --short --branch
git diff --stat
git diff --name-status @{u}...HEAD
git ls-files
```

Run `scripts/pre-push-check.sh` when present and executable, or explain if it cannot be run. Report the result as:

- `判定`: 問題なし / 注意あり / 危険
- `根拠`: the concrete files, commands, or lines that support the result
- `次の一手`: the smallest useful fix or follow-up

Do not push, commit, or install hooks merely because this skill is active. Only perform those mutations when the user asks for them.
