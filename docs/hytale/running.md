# Running a Hytale Server

## Launch

The official manual uses:

```bash
java -jar HytaleServer.jar --assets PathToAssets.zip
```

You can inspect all server arguments via:

```bash
java -jar HytaleServer.jar --help
```

The manual highlights these options:

- `--assets <Path>` — asset directory/zip (default shown as `..\\HytaleAssets`)
- `--auth-mode <authenticated|offline>`
- `--bind <InetSocketAddress>` — bind address (default `0.0.0.0:5520`)
- `--backup`, `--backup-dir <Path>`, `--backup-frequency <Integer>`

## Authentication

After first launch, authenticate your server using the server console:

```text
/auth login device
```

You will receive a URL + device code (valid for 900 seconds). After completing the browser authorization, the server becomes authenticated and can accept player connections.

Notes from the official docs:

- Servers require authentication to communicate with Hytale service APIs and to counter abuse.
- There is a default limit of **100 servers per Hytale game license**.

For large fleets / hosting providers, see `server-provider-auth.md`.

## Ports, firewall & NAT

- **Default port:** `5520`
- Change it with `--bind`, e.g.:

```bash
java -jar HytaleServer.jar --assets PathToAssets.zip --bind 0.0.0.0:25565
```

Important: Hytale uses **QUIC over UDP**. Configure your firewall and port forwarding for **UDP**, not TCP.

Examples from the manual:

- **Windows Defender Firewall**

```powershell
New-NetFirewallRule -DisplayName "Hytale Server" -Direction Inbound -Protocol UDP -LocalPort 5520 -Action Allow
```

- **Linux (iptables)**

```bash
sudo iptables -A INPUT -p udp --dport 5520 -j ACCEPT
```

- **Linux (ufw)**

```bash
sudo ufw allow 5520/udp
```

NAT considerations (manual highlights):

- Make sure the forward is specifically **UDP**
- Symmetric NAT can cause issues (consider VPS/dedicated)

## File structure

The manual lists:

- `.cache/` — cache for optimized files
- `logs/` — server logs
- `mods/` — installed mods
- `universe/` — world and player save data
- `bans.json` — banned players
- `config.json` — server configuration
- `permissions.json` — permission configuration
- `whitelist.json` — whitelisted players

Universe structure:

- `universe/worlds/` contains playable worlds
- each world has its own `config.json`
- each world runs on its own main thread and off-loads parallel work into a shared thread pool

## Configuration file behavior

The official docs note:

- config files are read on startup
- in-game actions can write/overwrite them
- manual edits while the server is running are likely to be overwritten
