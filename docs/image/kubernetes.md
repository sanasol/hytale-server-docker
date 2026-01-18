# Kubernetes

This repository ships optional Kubernetes deployment assets for the Docker image:

- Docker Hub: `hybrowse/hytale-server`
- GHCR: `ghcr.io/hybrowse/hytale-server`

The manifests are designed with:

- secure defaults (non-root, minimal privileges)
- operational flexibility (Helm values or Kustomize overlays)
- no redistribution of proprietary Hytale server files

## Important: server files and persistence

The container expects its data under `/data`:

- `/data/Assets.zip`
- `/data/server/HytaleServer.jar`

Whether you persist `/data` depends on your operation model:

- If you want the server files, mods, backups, and generated state to survive restarts, use a PVC.
- If you want fully ephemeral nodes and sync state elsewhere (e.g. an external backup/sync process), you can run without a PVC.

If you enable auto-download (`HYTALE_AUTO_DOWNLOAD=true`), the server files can be downloaded at runtime into `/data`.

Note: We intentionally do not enable a read-only root filesystem by default. The official server workflow can require writing a machine-id (and while the image has workarounds, a strictly read-only root filesystem can still be surprising operationally).

## Helm

The Helm chart lives in `deploy/helm/hytale-server`.

### Add the Helm repo (GitHub Pages)

After a release is published, the Helm repository is available at:

- `https://hybrowse.github.io/hytale-server-docker`

Add it:

```bash
helm repo add hybrowse https://hybrowse.github.io/hytale-server-docker
helm repo update
```

### Install (ephemeral /data, no PVC)

This is the safest default for "try it out" use-cases:

```bash
helm install hytale hybrowse/hytale-server \
  --set persistence.enabled=false \
  --set env.HYTALE_AUTO_DOWNLOAD=true
```

Notes:

- `/data` will be an `emptyDir` (lost on restart).
- This is best suited for dev/testing or setups that synchronize state elsewhere.

### Install with persistence (StatefulSet)

Persistence is enabled by default in the Helm chart.
You can tune the requested size; a reasonable starting point is 5Gi.

```bash
helm install hytale hybrowse/hytale-server \
  --set persistence.enabled=true \
  --set persistence.size=5Gi
```

### Switch workload type to Deployment

If you explicitly prefer a Deployment:

```bash
helm install hytale hybrowse/hytale-server \
  --set workload.kind=Deployment
```

If you want persistence with Deployment mode, the chart creates a PVC unless you point it at an existing one:

```bash
helm install hytale hybrowse/hytale-server \
  --set workload.kind=Deployment \
  --set persistence.enabled=true \
  --set persistence.existingClaim=my-existing-claim
```

### Exposing the UDP port

By default, the chart creates a `ClusterIP` Service (internal).

For external exposure, options depend on your cluster:

- `service.type=LoadBalancer` (common on managed clusters)
- `service.type=NodePort` (requires firewall / node routing)

Examples:

```bash
helm install hytale hybrowse/hytale-server \
  --set service.type=LoadBalancer
```

```bash
helm install hytale hybrowse/hytale-server \
  --set service.type=NodePort \
  --set service.nodePort=30520
```

## Kustomize

Kustomize manifests live in `deploy/kustomize`.

### Base

`deploy/kustomize/base` is intentionally minimal and uses an `emptyDir` for `/data`.

```bash
kustomize build deploy/kustomize/base | kubectl apply -f -
```

Alternatively, if you prefer using kubectl's built-in kustomize support:

```bash
kubectl kustomize deploy/kustomize/base | kubectl apply -f -
```

### Overlays

- `deploy/kustomize/overlays/development`: enables auto-download and uses `imagePullPolicy: Always`
- `deploy/kustomize/overlays/production`: enables PVC, PDB, NetworkPolicy, and backups

```bash
kustomize build deploy/kustomize/overlays/development | kubectl apply -f -
```

With kubectl:

```bash
kubectl kustomize deploy/kustomize/overlays/development | kubectl apply -f -
```

```bash
kustomize build deploy/kustomize/overlays/production | kubectl apply -f -
```

With kubectl:

```bash
kubectl kustomize deploy/kustomize/overlays/production | kubectl apply -f -
```

## Validation

Locally you can validate that the Kubernetes manifests render and pass schema validation:

```bash
task k8s:test
```
