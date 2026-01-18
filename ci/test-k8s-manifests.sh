#!/bin/sh
set -eu

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  echo "PASS: $*" >&2
}

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CHART_DIR="${ROOT_DIR}/deploy/helm/hytale-server"
KUSTOMIZE_DIR="${ROOT_DIR}/deploy/kustomize"

HELM_IMAGE="alpine/helm:3.14.4"
KUSTOMIZE_IMAGE="ghcr.io/kubernetes-sigs/kustomize/kustomize:v5.4.1"
KUBECONFORM_IMAGE="ghcr.io/yannh/kubeconform:v0.6.7"
K8S_VERSION="1.29.0"

[ -d "${CHART_DIR}" ] || fail "helm chart dir not found: ${CHART_DIR}"
[ -d "${KUSTOMIZE_DIR}" ] || fail "kustomize dir not found: ${KUSTOMIZE_DIR}"

# Helm lint
if ! docker run --rm -v "${ROOT_DIR}:/work" -w /work "${HELM_IMAGE}" lint deploy/helm/hytale-server >/dev/null; then
  fail "helm lint failed"
fi
pass "helm lint"

# Helm template + schema validation
if ! docker run --rm -v "${ROOT_DIR}:/work" -w /work "${HELM_IMAGE}" template test deploy/helm/hytale-server |
  docker run --rm -i "${KUBECONFORM_IMAGE}" -strict -summary -kubernetes-version "${K8S_VERSION}" -ignore-missing-schemas; then
  fail "helm template kubeconform failed"
fi
pass "helm template + kubeconform"

# Kustomize builds + schema validation
for p in base overlays/development overlays/production overlays/auto-download overlays/pdb overlays/network-policy; do
  if ! docker run --rm -v "${ROOT_DIR}:/work" -w /work "${KUSTOMIZE_IMAGE}" build "deploy/kustomize/${p}" |
    docker run --rm -i "${KUBECONFORM_IMAGE}" -strict -summary -kubernetes-version "${K8S_VERSION}" -ignore-missing-schemas; then
    fail "kustomize build kubeconform failed: ${p}"
  fi
  pass "kustomize build + kubeconform: ${p}"
done

pass "k8s manifests"
