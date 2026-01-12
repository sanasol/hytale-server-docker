# Tips & Tricks

## Installing mods

The official manual states:

- download mods (`.zip` or `.jar`) from sources such as CurseForge
- drop them into `mods/`

## Disable Sentry crash reporting

The official docs recommend disabling Sentry during active plugin development:

```bash
java -jar HytaleServer.jar --assets PathToAssets.zip --disable-sentry
```

## Leverage the Ahead-of-Time (AOT) cache

Hytale ships with a pre-trained AOT cache (`HytaleServer.aot`) that improves boot times by skipping JIT warmup.
The manual references JEP-514.

Example:

```bash
java -XX:AOTCache=HytaleServer.aot -jar HytaleServer.jar --assets PathToAssets.zip
```

## Recommended plugins

The official manual lists plugins maintained by hosting partners:

- `Nitrado:WebServer` — base plugin for web apps and APIs
- `Nitrado:Query` — exposes server status (player counts, etc.) via HTTP
- `Nitrado:PerformanceSaver` — dynamically limits view distance based on resource usage
- `ApexHosting:PrometheusExporter` — exposes detailed server and JVM metrics

## View distance

The manual highlights view distance as the main driver for RAM usage.

Recommendation:

- limit maximum view distance to **12 chunks (384 blocks)** for performance and gameplay

Comparison given in the manual:

- Minecraft defaults to 10 chunks (160 blocks)
- Hytale default of 384 blocks is roughly equivalent to 24 Minecraft chunks

## Memory tuning

Hytale's docs recommend experimenting with `-Xmx` to set explicit heap limits.
A typical symptom of memory pressure is increased CPU usage due to garbage collection.
