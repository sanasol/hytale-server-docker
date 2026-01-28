# Pterodactyl Eggs for Hytale Server

Pterodactyl Panel eggs for running Hytale game servers.

## Available Eggs

| Egg | Description | Auth Required |
|-----|-------------|---------------|
| [`egg-hytale-server.json`](egg-hytale-server.json) | **Recommended** - Auto-downloads server files | No |
| [`egg-hytale-server-official.json`](egg-hytale-server-official.json) | Downloads from official Hytale servers | Yes (device code) |

Both eggs support **F2P and official licensed clients** connecting to the same server.

---

## Quick Start

### 1. Import the Egg

1. Go to Pterodactyl Admin Panel → Nests
2. Create a new nest or use existing one (e.g., "Game Servers")
3. Click "Import Egg"
4. Upload `egg-hytale-server.json` (recommended)

### 2. Create Server

1. Go to Servers → Create New
2. Select the "Hytale Server" egg
3. **Important**: Allocate a **UDP port** (Hytale uses UDP, not TCP)
4. Set memory (minimum 4GB recommended)
5. Create and start the server

### 3. First Run

The server will automatically:
- Download HytaleServer.jar (~80 MB)
- Download Assets.zip (~3.3 GB)
- Patch for dual authentication
- Fetch F2P auth tokens
- Start the server

---

## Egg Comparison

### Hytale Server (Recommended)

```
egg-hytale-server.json
```

- **No authentication required** - downloads from F2P host
- Server files are pre-patched
- Faster setup - no device code flow
- Best for most users

### Hytale Server (Official Download)

```
egg-hytale-server-official.json
```

- Downloads from official Hytale servers
- **Requires device code authentication** on first run
- Check console for authentication URL and code
- Use this if you need official/latest server files

---

## Connecting Clients

### F2P Clients

Connect directly using [Hytale F2P Launcher](https://github.com/amiayweb/Hytale-F2P) - no additional setup needed.

### Official/Licensed Clients

To allow players with official Hytale game licenses to connect, the **server admin** must run these commands in the **Pterodactyl console** (server console):

```
/auth logout
/auth persistence Encrypted
/auth login device
```

Then complete Hytale authentication in browser. This gives the server official Hytale tokens so it can authenticate licensed clients. Only needs to be done once per server.

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_DOMAIN` | `auth.sanasol.ws` | F2P authentication server |
| `HYTALE_PORT` | `5520` | Server UDP port (auto-set by Pterodactyl) |
| `HYTALE_SERVER_NAME` | `Hytale Server` | Display name for your server |
| `AUTH_MODE` | `authenticated` | Auth mode: authenticated, unauthenticated, singleplayer |
| `MEMORY_OVERHEAD` | `256` | MB reserved for JVM overhead |
| `JVM_ARGS` | - | Additional JVM arguments |
| `ENABLE_BACKUPS` | `0` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `30` | Backup interval in minutes |
| `ALLOW_OP` | `1` | Allow /op command |
| `FORCE_DOWNLOAD` | `0` | Re-download server files |

### Port Configuration

**Important**: Hytale uses **UDP** protocol.

When allocating ports in Pterodactyl:
1. Go to Server → Network
2. Add allocation with your desired port
3. Ensure the port is configured for **UDP** traffic
4. Server will automatically use the allocated port

---

## Troubleshooting

### Can't connect to server

1. **Check port protocol** - Must be UDP, not TCP
2. **Check firewall** - UDP port must be open on Wings server
3. **Check allocation** - Server must have the port allocated

```bash
# Test UDP connectivity (from client machine)
nc -u -v your-server.com 5520
```

### Download fails

1. Check internet connectivity on Wings server
2. Try setting `FORCE_DOWNLOAD=1` to re-download
3. Check disk space (~4GB needed)

### Official download authentication

For `egg-hytale-server-official.json`:
1. Check console for device code URL
2. Open URL in browser
3. Enter the code shown in console
4. Wait for download to complete
5. Re-run installer if needed

### Server starts but no logs

Check if the server is actually binding to the correct port:
```
Server Port: 5520 (UDP)
  (from Pterodactyl allocation)
```

If it says "from HYTALE_PORT variable or default", the port allocation may not be working correctly.

---

## Files Structure

After installation, the server directory contains:

```
/home/container/
├── HytaleServer.jar      # Server executable
├── Assets.zip            # Game assets (~3.3 GB)
├── start.sh              # Startup script
├── universe/             # World data (created on first run)
├── patcher/              # Dual auth patcher files
├── .server-id            # Persistent server ID
└── .patched_dual_auth    # Patch status flag
```

---

## Related Resources

- [Hytale Server Docker](https://github.com/sanasol/hytale-server-docker) - Docker images
- [Hytale F2P Launcher](https://github.com/amiayweb/Hytale-F2P) - Client launcher
- [Server List](https://santale.top) - Find Hytale servers

---

## Support

- Discord: https://discord.gg/gME8rUy3MB
- Issues: https://github.com/sanasol/hytale-server-docker/issues
