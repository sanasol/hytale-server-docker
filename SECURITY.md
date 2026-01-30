# Security Policy

## Supported versions

Security fixes are applied to the **latest released image tags** and the default branch.

## Reporting a vulnerability

Please **do not** open a public issue for security vulnerabilities.

Instead, use GitHub Security Advisories:

- https://github.com/sanasol/hytale-server-docker/security/advisories/new

Include:

- affected image tag(s)
- reproduction steps
- impact assessment
- any suggested fix

## Scope

This repository covers:

- container build files and scripts
- entrypoint/runtime behavior
- documentation that could lead to unsafe operations

Vulnerabilities in the **official Hytale server software** itself should be reported to Hypixel Studios via their official channels.

## Secrets & sensitive data

When reporting issues, never include:

- OAuth refresh/access tokens
- `.hytale-downloader-credentials.json`

**Note:** F2P server tokens are auto-fetched by the patched JAR on startup - no manual token management required.
