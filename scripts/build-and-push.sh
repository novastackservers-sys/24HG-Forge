#!/bin/bash
# HubOS Build & Push — Builds the OCI image and pushes to git.raggi.is registry
# Usage: ./scripts/build-and-push.sh [desktop|nvidia|deck|all]
#
# This is the primary build method since the repo is on Gitea (git.raggi.is)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
REGISTRY="git.raggi.is"
OWNER="admin"
DATE_TAG=$(date +%Y%m%d)

VARIANT="${1:-desktop}"

build_variant() {
    local variant="$1"
    local base_image

    case "$variant" in
        desktop) base_image="ghcr.io/ublue-os/bazzite" ;;
        nvidia)  base_image="ghcr.io/ublue-os/bazzite-nvidia" ;;
        deck)    base_image="ghcr.io/ublue-os/bazzite-deck" ;;
        *)
            echo "Unknown variant: $variant"
            echo "Usage: $0 [desktop|nvidia|deck|all]"
            return 1
            ;;
    esac

    local image_name="${REGISTRY}/${OWNER}/hubos-${variant}"

    echo ""
    echo "=============================="
    echo "Building HubOS (${variant})"
    echo "Base: ${base_image}:stable"
    echo "Image: ${image_name}"
    echo "=============================="
    echo ""

    cd "${ROOT_DIR}"

    # Build
    docker build \
        --build-arg BASE_IMAGE="${base_image}" \
        --build-arg BASE_TAG="stable" \
        -t "${image_name}:latest" \
        -t "${image_name}:${DATE_TAG}" \
        -f Containerfile \
        .

    echo ""
    echo "Build complete. Pushing..."

    # Push
    docker push "${image_name}:latest"
    docker push "${image_name}:${DATE_TAG}"

    echo ""
    echo "Pushed: ${image_name}:latest"
    echo "Pushed: ${image_name}:${DATE_TAG}"
    echo ""
    echo "Users can rebase with:"
    echo "  rpm-ostree rebase ostree-unverified-registry:${image_name}:latest"
    echo ""
}

# Login to registry
echo "Logging into ${REGISTRY}..."
docker login "${REGISTRY}" -u "${OWNER}" 2>/dev/null || {
    echo "Login failed. Run: docker login ${REGISTRY} -u ${OWNER}"
    exit 1
}

if [ "$VARIANT" = "all" ]; then
    for v in desktop nvidia deck; do
        build_variant "$v"
    done
else
    build_variant "$VARIANT"
fi

echo "=============================="
echo "All done!"
echo "=============================="
