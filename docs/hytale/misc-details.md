# Misc Details

## JVM arguments

The official manual points to JVM parameters such as:

- `-Xms` — initial heap
- `-Xmx` — maximum heap

Use these to control memory usage in production.

## Protocol updates

The manual notes:

- the protocol uses a hash to verify client/server compatibility
- if hashes do not match *exactly*, the connection is rejected

Current limitation:

- client and server must be on the exact same protocol version
- when an update is released, servers must update immediately or updated clients cannot connect

Planned improvement:

- a tolerance window allowing approximately `±2` versions

## Configuration files

The manual highlights:

- config files are read on startup
- config files are written to when in-game actions occur
- manual changes while the server is running are likely to be overwritten

## Maven Central artifact

The manual states the server jar will be published to Maven Central for modding projects:

```xml
<dependency>
  <groupId>com.hypixel.hytale</groupId>
  <artifactId>Server</artifactId>
</dependency>
```

Exact versioning details are pending.
