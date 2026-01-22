[![Discord](https://img.shields.io/discord/1459154799407665397?label=Join%20Discord)](https://hybrowse.gg/discord)
[![Docker Pulls](https://img.shields.io/docker/pulls/hybrowse/hytale-server)](https://hub.docker.com/r/hybrowse/hytale-server)

# Hytale Server Docker Image

**🐳 Production-ready Docker image for dedicated Hytale servers.**

Automatic CurseForge mod management, auto-download with smart update detection, Helm chart, CLI, easy configuration, and quick troubleshooting.

Brought to you by [Hybrowse](https://hybrowse.gg) and the developer of [setupmc.com](https://setupmc.com).

---

## Custom Auth Server Support (Experimental)

This fork includes support for custom authentication servers, allowing you to run a complete F2P Hytale setup.

> **Warning**: This is experimental and for educational purposes only.

### Public Test Server (Default)

**Works out of the box!** By default, all configurations use `sanasol.ws` - a public test auth server. You can start using this immediately without setting up your own authentication server.

#### Quick Test (No Setup Required)

1. **Download the pre-built launcher**: [Hytale F2P Launcher v2.0.2b](https://github.com/amiayweb/Hytale-F2P/releases/tag/v2.0.2b)
2. **Connect to the public game server**: `ht.vboro.de:5720`

No server setup needed - just download, launch, and play!

- **All cosmetics unlocked** - full access to character customization
- **Cosmetics saved by username** - your skin/cosmetic choices persist between sessions

> **Note**: There is no password authentication - anyone can use any username. If you use a username someone else has used, you'll see their cosmetics. Use a unique username for testing.

#### Build from Source

Use the [Hytale F2P Launcher](https://github.com/amiayweb/Hytale-F2P) with default configuration (uses `sanasol.ws` by default with dual auth support).

> **Note**: For production use or privacy, you can set up your own auth server using [hytale-auth-server](https://github.com/sanasol/hytale-auth-server).

### Related Projects

| Project | Description |
|---------|-------------|
| [hytale-auth-server](https://github.com/sanasol/hytale-auth-server) | Authentication server |
| [Hytale F2P Launcher](https://github.com/amiayweb/Hytale-F2P) | Game launcher with dual auth support |
| [hytale-server-docker](https://github.com/sanasol/hytale-server-docker) | Dedicated server Docker image (this repo) |

### Custom Auth Features

- **Automatic domain patching**: Patches `HytaleServer.jar` to use your custom auth domain
- **Token auto-fetch**: Automatically fetches server tokens from your auth server on startup
- **Configurable domain**: Set your 10-character domain via environment variable

### Custom Auth Configuration

```yaml
services:
  hytale:
    build: .  # Build from this repo instead of using hybrowse image
    environment:
      # Custom auth server configuration
      HYTALE_AUTH_DOMAIN: "sanasol.ws"     # Your 10-character domain
      HYTALE_PATCH_SERVER: "true"           # Enable automatic JAR patching
      HYTALE_AUTO_FETCH_TOKENS: "true"      # Fetch tokens from auth server
      HYTALE_AUTH_SERVER: "https://sessions.sanasol.ws"

      # Standard configuration
      HYTALE_AUTO_DOWNLOAD: "true"
      HYTALE_AUTH_MODE: "authenticated"
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/data
```

### Quick Start (Using Public Test Server)

Using the default `sanasol.ws` auth server - no auth server setup needed:

1. **Start this dedicated server**:
   ```bash
   git clone https://github.com/sanasol/hytale-server-docker.git
   cd hytale-server-docker
   docker compose build
   docker compose up -d
   ```

2. **Launch with the F2P launcher** ([Hytale F2P Launcher](https://github.com/amiayweb/Hytale-F2P)):
   - Download from [releases](https://github.com/amiayweb/Hytale-F2P/releases/tag/v2.0.2b)
   - Or build from source:
   ```bash
   git clone https://github.com/amiayweb/Hytale-F2P.git
   cd Hytale-F2P
   npm install
   npm start
   ```

### Complete Setup (Own Auth Server)

For running your own auth server with a custom domain:

1. **Start the auth server** ([hytale-auth-server](https://github.com/sanasol/hytale-auth-server)):
   ```bash
   git clone https://github.com/sanasol/hytale-auth-server.git
   cd hytale-auth-server
   # Edit compose.yaml with your domain
   docker compose up -d
   ```

2. **Start this dedicated server**:
   ```bash
   git clone https://github.com/sanasol/hytale-server-docker.git
   cd hytale-server-docker
   # Edit compose.yaml with your domain
   docker compose build
   docker compose up -d
   ```

3. **Launch with the F2P launcher** ([Hytale F2P Launcher](https://github.com/amiayweb/Hytale-F2P)):
   - Download from [releases](https://github.com/amiayweb/Hytale-F2P/releases/tag/v2.0.2b)
   - Or build from source:
   ```bash
   git clone https://github.com/amiayweb/Hytale-F2P.git
   cd Hytale-F2P
   npm install
   # Set HYTALE_AUTH_DOMAIN=yourdomain environment variable
   npm start
   ```

---

## Image

- **Image (Docker Hub)**: [`hybrowse/hytale-server`](https://hub.docker.com/r/hybrowse/hytale-server)
- **Mirror (GHCR)**: [`ghcr.io/hybrowse/hytale-server`](https://ghcr.io/hybrowse/hytale-server)

## Community

Join the **Hybrowse Discord Server** to get help and stay up to date: https://hybrowse.gg/discord

## Quickstart

```yaml
services:
  hytale:
    image: hybrowse/hytale-server:latest
    environment:
      HYTALE_AUTO_DOWNLOAD: "true"
    ports:
      - "5520:5520/udp"
    volumes:
      - ./data:/data
    tty: true
    stdin_open: true
    restart: unless-stopped
```

```bash
docker compose up -d
```

> [!IMPORTANT]
> **Two authentication steps required:**
>
> 1. **Downloader auth** (first run): follow the URL + device code in the logs to download server files
> 2. **Server auth** (after startup): attach to the console (`docker compose attach hytale`), then run `/auth persistence Encrypted` followed by `/auth login device`

Full guide: [`docs/image/quickstart.md`](docs/image/quickstart.md)

Troubleshooting: [`docs/image/troubleshooting.md`](docs/image/troubleshooting.md)

Automation: you can send server console commands from scripts via `hytale-cli`:

```bash
docker exec hytale hytale-cli send "/say Server is running!"
```

See: [`docs/image/configuration.md`](docs/image/configuration.md#send-console-commands-hytale-cli)

## Documentation

- [`docs/image/quickstart.md`](docs/image/quickstart.md) — start here
- [`docs/image/configuration.md`](docs/image/configuration.md) — environment variables, JVM tuning
- [`docs/image/kubernetes.md`](docs/image/kubernetes.md) — Helm chart, Kustomize overlays, and Kubernetes deployment notes
- [`docs/image/curseforge-mods.md`](docs/image/curseforge-mods.md) — automatic CurseForge mod download and updates
- [`docs/image/troubleshooting.md`](docs/image/troubleshooting.md) — common issues
- [`docs/image/backups.md`](docs/image/backups.md) — backup configuration
- [`docs/image/server-files.md`](docs/image/server-files.md) — manual provisioning (arm64, etc.)
- [`docs/image/upgrades.md`](docs/image/upgrades.md) — upgrade guidance
- [`docs/image/security.md`](docs/image/security.md) — security hardening

## Why this image

- **Security-first defaults** (least privilege; credentials/tokens treated as secrets)
- **Operator UX** (clear startup validation and actionable errors)
- **Performance-aware** (sane JVM defaults; optional AOT cache usage)
- **Predictable operations** (documented data layout and upgrade guidance)

## Java

Hytale requires **Java 25**.
This image uses **Adoptium / Eclipse Temurin 25**.

## Planned features

See [`ROADMAP.md`](ROADMAP.md) for details. Highlights:

- **Planned next**: graceful shutdown guidance, basic healthcheck (with a way to disable), diagnostics helpers, observability guidance, provider-grade patterns
 
## Documentation
 
- [`docs/image/`](docs/image/): Image usage & configuration
- [`docs/hytale/`](docs/hytale/): internal notes (not end-user image docs)
 
## Contributing & Security
 
- [`CONTRIBUTING.md`](CONTRIBUTING.md)
- [`SECURITY.md`](SECURITY.md)

## Local verification

You can build and run basic container-level validation tests locally:

```bash
task verify
```

Install Task:

- https://taskfile.dev/
 
## License
 
See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE).
