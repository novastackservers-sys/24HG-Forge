#!/bin/bash
# Build 24HG Forge OCI image locally using podman
# Usage: ./scripts/build-local.sh [variant]
# Variants: desktop (default), nvidia, deck

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

VARIANT="${1:-desktop}"

case "$VARIANT" in
    desktop)
        BASE_IMAGE="ghcr.io/ublue-os/bazzite"
        ;;
    nvidia)
        BASE_IMAGE="ghcr.io/ublue-os/bazzite-nvidia"
        ;;
    deck)
        BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
        ;;
    *)
        echo "Unknown variant: $VARIANT"
        echo "Usage: $0 [desktop|nvidia|deck]"
        exit 1
        ;;
esac

BASE_TAG="stable"
IMAGE_NAME="forge-${VARIANT}"

echo "=============================="
echo "Building 24HG Forge (${VARIANT})"
echo "Base: ${BASE_IMAGE}:${BASE_TAG}"
echo "=============================="

cd "${ROOT_DIR}"

# Build the OCI image
podman build \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg BASE_TAG="${BASE_TAG}" \
    -t "${IMAGE_NAME}:latest" \
    -f Containerfile \
    .

echo ""
echo "=============================="
echo "Build complete: ${IMAGE_NAME}:latest"
echo ""
echo "To test in a VM:"
echo "  1. Push to a registry, or"
echo "  2. Use 'podman save ${IMAGE_NAME}:latest -o ${IMAGE_NAME}.tar' and load in VM"
echo ""
echo "To rebase an existing Fedora Atomic install:"
echo "  rpm-ostree rebase ostree-unverified-image:containers-storage:localhost/${IMAGE_NAME}:latest"
echo "=============================="
