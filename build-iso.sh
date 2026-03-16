#!/usr/bin/env bash
set -euo pipefail

# HubOS ISO Builder
# Builds the OCI image, flattens it for fast install, creates a bootable ISO

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="hubos"
IMAGE_TAG="${1:-latest}"
IMAGE_REF="localhost/${IMAGE_NAME}:${IMAGE_TAG}"
FLAT_REF="localhost/${IMAGE_NAME}-flat:${IMAGE_TAG}"
ISO_DIR="${SCRIPT_DIR}/iso-output"
VARIANT="${2:-desktop}"  # desktop or nvidia

# Select base image based on variant
case "${VARIANT}" in
    nvidia)
        BASE_IMAGE="ghcr.io/ublue-os/bazzite-nvidia"
        ;;
    desktop|*)
        BASE_IMAGE="ghcr.io/ublue-os/bazzite"
        ;;
esac

echo "══════════════════════════════════════════"
echo "  HubOS ISO Builder"
echo "  Variant: ${VARIANT}"
echo "  Base: ${BASE_IMAGE}"
echo "  Tag: ${IMAGE_TAG}"
echo "══════════════════════════════════════════"

# Step 1: Build OCI image
echo ""
echo "▶ Step 1/4: Building OCI container image..."
podman build \
    --tag "${IMAGE_REF}" \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg BASE_TAG=stable \
    --file "${SCRIPT_DIR}/$([ "${VARIANT}" = "nvidia" ] && echo Containerfile.nvidia || echo Containerfile)" \
    "${SCRIPT_DIR}"

echo "✓ Image built: ${IMAGE_REF}"
echo "  Size: $(podman image inspect "${IMAGE_REF}" --format '{{.Size}}' | numfmt --to=iec 2>/dev/null || echo 'unknown')"

# Step 2: Flatten image to single layer (dramatically speeds up Anaconda install)
echo ""
echo "▶ Step 2/4: Flattening image to single layer (speeds up install)..."
CONTAINER_ID=$(podman create "${IMAGE_REF}" /bin/bash)
podman export "${CONTAINER_ID}" | podman import - "${FLAT_REF}"
podman rm "${CONTAINER_ID}" >/dev/null

# Copy labels and config from original image
echo "FROM ${FLAT_REF}" > /tmp/hubos-flatten.Dockerfile
echo 'LABEL org.opencontainers.image.title="HubOS"' >> /tmp/hubos-flatten.Dockerfile
echo 'LABEL org.opencontainers.image.description="24HG Gaming Distribution"' >> /tmp/hubos-flatten.Dockerfile
echo 'CMD ["/bin/bash"]' >> /tmp/hubos-flatten.Dockerfile
podman build --tag "${FLAT_REF}" -f /tmp/hubos-flatten.Dockerfile /tmp/
rm -f /tmp/hubos-flatten.Dockerfile

LAYERS=$(podman inspect "${FLAT_REF}" --format '{{len .RootFS.Layers}}' 2>/dev/null || echo "?")
echo "✓ Flattened: ${LAYERS} layer(s) (was 90+)"

# Step 3: Create ISO using Universal Blue's ISO builder
echo ""
echo "▶ Step 3/4: Creating bootable ISO..."
mkdir -p "${ISO_DIR}"

podman run --rm --privileged \
    --volume "${ISO_DIR}:/build-container-installer/build:z" \
    --volume /var/lib/containers/storage:/var/lib/containers/storage \
    ghcr.io/jasonn3/build-container-installer:latest \
    IMAGE_REPO="localhost" \
    IMAGE_NAME="${IMAGE_NAME}-flat" \
    IMAGE_TAG="${IMAGE_TAG}" \
    VARIANT="Kinoite" \
    ISO_NAME="hubos-${VARIANT}-${IMAGE_TAG}.iso" \
    ENROLLMENT_PASSWORD="hubos"

echo "✓ ISO created"

# Step 4: Generate checksums
echo ""
echo "▶ Step 4/4: Generating checksums..."
cd "${ISO_DIR}"
ISO_FILE="hubos-${VARIANT}-${IMAGE_TAG}.iso"
if [ -f "${ISO_FILE}" ]; then
    sha256sum "${ISO_FILE}" > "${ISO_FILE}.sha256"
    echo "✓ SHA256: $(cat "${ISO_FILE}.sha256")"
    echo ""
    echo "══════════════════════════════════════════"
    echo "  Build complete!"
    echo "  ISO: ${ISO_DIR}/${ISO_FILE}"
    echo "  Size: $(du -h "${ISO_FILE}" | cut -f1)"
    echo "  SHA256: ${ISO_DIR}/${ISO_FILE}.sha256"
    echo ""
    echo "  Flattened image = faster install (~5 min vs 30+ min)"
    echo "══════════════════════════════════════════"
else
    echo "✗ ISO file not found. Check build logs."
    exit 1
fi

# Cleanup flattened image
podman rmi "${FLAT_REF}" 2>/dev/null || true
