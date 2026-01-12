# Server Setup

## System requirements

- **Java:** Hytale dedicated servers require **Java 25**.
- **Memory:** At least **4GB RAM**.
- **Architecture:** **x64** and **arm64** are supported.

Resource usage depends heavily on player behavior.

- **CPU drivers:** High player/entity counts (NPCs, mobs)
- **RAM drivers:** Large loaded world area (high view distance, players exploring independently)

If you see high CPU usage from garbage collection, experiment with setting a clearer heap cap via Java's `-Xmx`.

## Installing Java 25

Hytale recommends installing Java 25 (e.g. via Adoptium/Temurin).

Verify:

```bash
java --version
```

The official manual shows output like:

```text
openjdk 25.0.1 2025-10-21 LTS
OpenJDK Runtime Environment Temurin-25.0.1+8 (build 25.0.1+8-LTS)
OpenJDK 64-Bit Server VM Temurin-25.0.1+8 (build 25.0.1+8-LTS, mixed mode, sharing)
```

## Obtaining server files

You need both:

- the **server files**
- **`Assets.zip`**

### Option A: Copy from launcher installation

Good for quick testing, but annoying to keep updated.

Paths documented by Hytale:

- **Windows:** `%appdata%\Hytale\install\release\package\game\latest`
- **Linux:** `$XDG_DATA_HOME/Hytale/install/release/package/game/latest`
- **macOS:** `~/Application Support/Hytale/install/release/package/game/latest`

Copy the **`Server/`** folder and **`Assets.zip`** to your server folder.

### Option B: Hytale Downloader CLI (recommended)

Best for production and updates.

The official docs provide the download here:

- https://downloader.hytale.com/hytale-downloader.zip

The tool uses OAuth2 Device Code flow and stores credentials locally.

Basic commands (as documented):

- `./hytale-downloader` — download latest release
- `./hytale-downloader -print-version` — show game version without downloading
- `./hytale-downloader -download-path /path/to/game.zip` — download to specific file
- `./hytale-downloader -patchline pre-release` — download a different patchline
- `./hytale-downloader -skip-update-check` — disable downloader self-update check

Troubleshooting highlights:

- If auth breaks: delete `.hytale-downloader-credentials.json` and retry
- If device code expired: restart the tool to get a new code

## Updates

The official docs require both:

- the **server files**
- **`Assets.zip`**

Practical guidance:

- Treat server files and `Assets.zip` as a **matched set** for a given release.
- When you update the server, update `Assets.zip` alongside it.
- Using the official Hytale Downloader is the simplest way to keep them in sync.
