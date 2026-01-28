#!/bin/bash
# Build and push multi-arch Docker image to GitHub Container Registry
# Usage: ./build.sh [--push] [--tag TAG]

set -e

# Configuration
REGISTRY="ghcr.io"
IMAGE_NAME="sanasol/hytale-server-docker"
DEFAULT_TAG="latest"
PLATFORMS="linux/amd64,linux/arm64"

# Parse arguments
PUSH=false
TAG="${DEFAULT_TAG}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --push)
      PUSH=true
      shift
      ;;
    --tag)
      TAG="$2"
      shift 2
      ;;
    --help|-h)
      echo "Usage: $0 [--push] [--tag TAG]"
      echo ""
      echo "Options:"
      echo "  --push       Push image to registry after building"
      echo "  --tag TAG    Tag for the image (default: latest)"
      echo ""
      echo "Examples:"
      echo "  $0                    # Build locally only"
      echo "  $0 --push             # Build and push with 'latest' tag"
      echo "  $0 --push --tag v1.0  # Build and push with 'v1.0' tag"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "============================================"
echo "Hytale F2P Server Docker Build"
echo "============================================"
echo "Image: ${FULL_IMAGE}"
echo "Platforms: ${PLATFORMS}"
echo "Push: ${PUSH}"
echo ""

# Check if logged in to registry (only if pushing)
if [ "$PUSH" = true ]; then
  echo "Checking registry authentication..."
  if ! grep -q "${REGISTRY}" ~/.docker/config.json 2>/dev/null; then
    echo ""
    echo "Not logged in to ${REGISTRY}. Please login first:"
    echo "  echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
    echo ""
    echo "Or use GitHub CLI:"
    echo "  gh auth token | docker login ghcr.io -u USERNAME --password-stdin"
    exit 1
  fi
  echo "Authenticated to ${REGISTRY}"
fi

# Setup buildx builder if not exists
BUILDER_NAME="hytale-multiarch"
if ! docker buildx inspect ${BUILDER_NAME} &>/dev/null; then
  echo "Creating buildx builder: ${BUILDER_NAME}"
  docker buildx create --name ${BUILDER_NAME} --use --bootstrap
else
  docker buildx use ${BUILDER_NAME}
fi

echo ""
echo "Building multi-arch image..."
echo ""

BUILD_ARGS=(
  "--platform" "${PLATFORMS}"
  "--tag" "${FULL_IMAGE}"
)

# Also tag as latest if building a version tag
if [ "$TAG" != "latest" ]; then
  BUILD_ARGS+=("--tag" "${REGISTRY}/${IMAGE_NAME}:latest")
fi

if [ "$PUSH" = true ]; then
  BUILD_ARGS+=("--push")
  echo "Building and pushing to ${REGISTRY}..."
else
  # --load only works with single platform, so override platforms
  BUILD_ARGS=("--tag" "${FULL_IMAGE}" "--load")
  echo "Building for local use (single platform only)..."
  echo "Note: Use --push to build multi-arch and push to registry"
fi

docker buildx build "${BUILD_ARGS[@]}" .

echo ""
echo "============================================"
if [ "$PUSH" = true ]; then
  echo "Image pushed successfully!"
  echo ""
  echo "Pull with:"
  echo "  docker pull ${FULL_IMAGE}"
  echo ""
  echo "Use in compose.yaml:"
  echo "  image: ${FULL_IMAGE}"
else
  echo "Image built successfully!"
  echo ""
  echo "Run locally:"
  echo "  docker run -d -p 5520:5520/udp ${FULL_IMAGE}"
fi
echo "============================================"
