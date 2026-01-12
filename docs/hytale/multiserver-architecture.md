# Multiserver Architecture

The official manual describes built-in mechanisms for routing players between servers.

## Player referral

Transfers a connected player to another server.

- server sends a referral packet: target host, port, optional payload (up to **4KB**)
- client opens a new connection to the target and presents the payload during handshake

API reference shown in the manual:

```text
PlayerRef.referToServer(@Nonnull final String host, final int port, @Nullable byte[] data)
```

Security warning (from the manual):

- the payload travels through the client and can be tampered with
- sign payloads cryptographically (e.g. HMAC with a shared secret) so the receiver can verify authenticity

## Connection redirect

During connection handshake a server can reject the player and redirect them to a different server.

API shown in the manual:

```text
PlayerSetupConnectEvent.referToServer(@Nonnull final String host, final int port, @Nullable byte[] data)
```

Use cases noted:

- load balancing
- regional routing
- enforcing lobby-first connections

## Disconnect fallback

When a player is unexpectedly disconnected (server crash, network interruption), the client can automatically reconnect to a configured fallback server.

The manual notes this feature is expected shortly after Early Access launch.

## Building a proxy

The manual suggests building custom proxy servers using Netty QUIC.

Packet definitions and protocol structure are available in `HytaleServer.jar`:

- `com.hypixel.hytale.protocol.packets`
