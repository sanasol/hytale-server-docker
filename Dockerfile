# Build stage for compiling the patcher
FROM eclipse-temurin:25-jdk AS patcher-builder

RUN apt-get update && apt-get install -y --no-install-recommends curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /build/lib
WORKDIR /build

# Download ASM libraries
RUN curl -sL "https://repo1.maven.org/maven2/org/ow2/asm/asm/9.6/asm-9.6.jar" -o lib/asm-9.6.jar \
  && curl -sL "https://repo1.maven.org/maven2/org/ow2/asm/asm-tree/9.6/asm-tree-9.6.jar" -o lib/asm-tree-9.6.jar \
  && curl -sL "https://repo1.maven.org/maven2/org/ow2/asm/asm-util/9.6/asm-util-9.6.jar" -o lib/asm-util-9.6.jar

# Copy and compile unified dual auth patcher
COPY issuer-patcher/DualAuthPatcher.java .
RUN javac -cp "lib/asm-9.6.jar:lib/asm-tree-9.6.jar:lib/asm-util-9.6.jar" -d . DualAuthPatcher.java

# Runtime stage
FROM eclipse-temurin:25-jre

RUN apt-get update \
  && apt-get install -y --no-install-recommends tini ca-certificates curl unzip zip perl jq \
  && rm -rf /var/lib/apt/lists/*

RUN groupadd -f hytale \
  && if ! id -u hytale >/dev/null 2>&1; then useradd -m -u 1000 -o -g hytale -s /usr/sbin/nologin hytale; fi \
  && touch /etc/machine-id \
  && chown hytale:hytale /etc/machine-id

RUN mkdir -p /data \
  && chown -R hytale:hytale /data

VOLUME ["/data"]
WORKDIR /data

COPY scripts/entrypoint.sh /usr/local/bin/hytale-entrypoint
COPY scripts/cfg-interpolate.sh /usr/local/bin/hytale-cfg-interpolate
COPY scripts/auto-download.sh /usr/local/bin/hytale-auto-download
COPY scripts/curseforge-mods.sh /usr/local/bin/hytale-curseforge-mods
COPY scripts/prestart-downloads.sh /usr/local/bin/hytale-prestart-downloads
COPY scripts/hytale-cli.sh /usr/local/bin/hytale-cli
COPY scripts/healthcheck.sh /usr/local/bin/hytale-healthcheck
COPY scripts/fetch-server-tokens.sh /usr/local/bin/hytale-fetch-tokens
COPY scripts/patch-dual-auth.sh /usr/local/bin/hytale-patch-dual-auth
RUN chmod 0755 /usr/local/bin/hytale-entrypoint /usr/local/bin/hytale-cfg-interpolate /usr/local/bin/hytale-auto-download /usr/local/bin/hytale-curseforge-mods /usr/local/bin/hytale-prestart-downloads /usr/local/bin/hytale-cli /usr/local/bin/hytale-healthcheck /usr/local/bin/hytale-fetch-tokens /usr/local/bin/hytale-patch-dual-auth

# Install patcher (pre-compiled from build stage)
# Copy all class files including any inner classes (DualAuthPatcher$*.class)
COPY --from=patcher-builder /build/lib /opt/issuer-patcher/lib
COPY --from=patcher-builder /build/*.class /opt/issuer-patcher/

USER hytale

HEALTHCHECK --interval=30s --timeout=5s --start-period=10m --retries=3 CMD ["/usr/local/bin/hytale-healthcheck"]

ENTRYPOINT ["/usr/bin/tini","--","/usr/local/bin/hytale-entrypoint"]
