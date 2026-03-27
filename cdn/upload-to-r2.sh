#!/usr/bin/env bash
set -euo pipefail
# 24HG — Upload ISO builds to Cloudflare R2 CDN

###############################################################################
# Configuration
###############################################################################
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly RCLONE_CONF="${SCRIPT_DIR}/rclone.conf"
readonly R2_REMOTE="r224hg"
readonly R2_BUCKET="24hg-iso"
readonly CDN_BASE_URL="https://cdn.24hgaming.com"
readonly API_BASE="https://os.24hgaming.com/api"
readonly ISO_DIR="${1:-$(dirname "$SCRIPT_DIR")/iso-output}"

# Colors
if [[ -t 1 ]]; then
    RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
    BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' BOLD='' DIM='' RESET=''
fi

log_info()  { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_ok()    { echo -e "${GREEN}[OK]${RESET} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${RESET} $*"; }
log_err()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()       { log_err "$@"; exit 1; }

###############################################################################
# Preflight checks
###############################################################################

preflight() {
    log_info "Running preflight checks..."

    command -v rclone &>/dev/null || die "rclone is not installed. Install with: curl https://rclone.org/install.sh | sudo bash"
    command -v sha256sum &>/dev/null || die "sha256sum not found"

    if [[ ! -f "$RCLONE_CONF" ]]; then
        die "rclone config not found at ${RCLONE_CONF}\nCopy rclone.conf.example and fill in your R2 credentials"
    fi

    if [[ ! -d "$ISO_DIR" ]]; then
        die "ISO directory not found: ${ISO_DIR}"
    fi

    local iso_count
    iso_count=$(find "$ISO_DIR" -maxdepth 1 -name "*.iso" -type f | wc -l)
    if (( iso_count == 0 )); then
        die "No ISO files found in ${ISO_DIR}"
    fi

    log_ok "Found ${iso_count} ISO file(s) in ${ISO_DIR}"
}

###############################################################################
# Generate checksums
###############################################################################

generate_checksums() {
    log_info "Generating SHA256 checksums..."

    local sums_file="${ISO_DIR}/SHA256SUMS"
    : > "$sums_file"

    for iso in "${ISO_DIR}"/*.iso; do
        [[ -f "$iso" ]] || continue
        local filename
        filename=$(basename "$iso")
        log_info "  Hashing ${filename}..."
        sha256sum "$iso" | sed "s|${ISO_DIR}/||" >> "$sums_file"
    done

    # Sign if GPG key is available
    if command -v gpg &>/dev/null && gpg --list-secret-keys "releases@24hgaming.com" &>/dev/null 2>&1; then
        log_info "Signing checksums with GPG..."
        gpg --detach-sign --armor -u "releases@24hgaming.com" "$sums_file"
        log_ok "Created ${sums_file}.asc"
    else
        log_warn "GPG key not available, skipping signature"
    fi

    log_ok "Checksums written to ${sums_file}"
}

###############################################################################
# Upload to R2
###############################################################################

upload_files() {
    log_info "Uploading to Cloudflare R2 (${R2_BUCKET})..."

    local uploaded=0

    for iso in "${ISO_DIR}"/*.iso; do
        [[ -f "$iso" ]] || continue
        local filename
        filename=$(basename "$iso")
        local size
        size=$(stat -c %s "$iso" 2>/dev/null || echo 0)
        local size_gb
        size_gb=$(echo "scale=2; $size/1073741824" | bc)

        log_info "Uploading ${filename} (${size_gb} GB)..."

        rclone copy "$iso" "${R2_REMOTE}:${R2_BUCKET}/iso/" \
            --config "$RCLONE_CONF" \
            --progress \
            --header-upload "Content-Type: application/x-iso9660-image" \
            --header-upload "Cache-Control: public, max-age=31536000, immutable" \
            --checksum \
            --transfers 1 \
            --s3-chunk-size 64M

        log_ok "Uploaded ${filename}"
        ((uploaded++))
    done

    # Upload checksums
    for sumfile in "${ISO_DIR}/SHA256SUMS" "${ISO_DIR}/SHA256SUMS.asc"; do
        if [[ -f "$sumfile" ]]; then
            local fname
            fname=$(basename "$sumfile")
            log_info "Uploading ${fname}..."

            rclone copy "$sumfile" "${R2_REMOTE}:${R2_BUCKET}/iso/" \
                --config "$RCLONE_CONF" \
                --header-upload "Content-Type: text/plain; charset=utf-8" \
                --header-upload "Cache-Control: public, max-age=3600"

            log_ok "Uploaded ${fname}"
        fi
    done

    # Upload metadata
    local latest_json="${ISO_DIR}/latest.json"
    if [[ -f "$latest_json" ]]; then
        log_info "Uploading metadata..."
        rclone copy "$latest_json" "${R2_REMOTE}:${R2_BUCKET}/metadata/" \
            --config "$RCLONE_CONF" \
            --header-upload "Content-Type: application/json" \
            --header-upload "Cache-Control: public, max-age=300"
    fi

    log_ok "Upload complete: ${uploaded} ISO file(s)"
}

###############################################################################
# Generate download URLs
###############################################################################

generate_urls() {
    log_info "Download URLs:"
    echo ""
    for iso in "${ISO_DIR}"/*.iso; do
        [[ -f "$iso" ]] || continue
        local filename
        filename=$(basename "$iso")
        echo -e "  ${BOLD}${filename}${RESET}"
        echo -e "  ${CDN_BASE_URL}/iso/${filename}"
        echo ""
    done
    echo -e "  ${BOLD}Checksums${RESET}"
    echo -e "  ${CDN_BASE_URL}/iso/SHA256SUMS"
    echo ""
}

###############################################################################
# Update mirror API
###############################################################################

update_mirror_api() {
    local api_key="${HG24_API_KEY:-}"
    if [[ -z "$api_key" ]]; then
        log_warn "HG24_API_KEY not set, skipping mirror API update"
        return 0
    fi

    log_info "Updating mirror list API..."

    local version=""
    for iso in "${ISO_DIR}"/*.iso; do
        [[ -f "$iso" ]] || continue
        version=$(basename "$iso" | grep -oP 'v[\d.]+' | head -1 || echo "unknown")
        break
    done

    local payload
    payload=$(cat <<JSON
{
    "cdn_url": "${CDN_BASE_URL}",
    "version": "${version}",
    "uploaded_at": "$(date -Iseconds)",
    "files": [
$(for iso in "${ISO_DIR}"/*.iso; do
    [[ -f "$iso" ]] || continue
    local fn=$(basename "$iso")
    local sz=$(stat -c %s "$iso" 2>/dev/null || echo 0)
    local hash=$(grep "$fn" "${ISO_DIR}/SHA256SUMS" 2>/dev/null | awk '{print $1}' || echo "")
    printf '        {"filename": "%s", "size": %s, "sha256": "%s"},\n' "$fn" "$sz" "$hash"
done | sed '$ s/,$//')
    ]
}
JSON
    )

    if curl -fsSL -X POST "${API_BASE}/releases/notify" \
         -H "Authorization: Bearer ${api_key}" \
         -H "Content-Type: application/json" \
         -d "$payload" &>/dev/null; then
        log_ok "Mirror API updated"
    else
        log_warn "Failed to update mirror API (non-fatal)"
    fi
}

###############################################################################
# Purge CDN cache
###############################################################################

purge_cdn_cache() {
    local cf_zone="${CF_ZONE_ID:-}"
    local cf_token="${CF_API_TOKEN:-}"

    if [[ -z "$cf_zone" || -z "$cf_token" ]]; then
        log_warn "CF_ZONE_ID / CF_API_TOKEN not set, skipping cache purge"
        return 0
    fi

    log_info "Purging Cloudflare CDN cache..."

    local purge_urls=()
    purge_urls+=("${CDN_BASE_URL}/iso/SHA256SUMS")
    purge_urls+=("${CDN_BASE_URL}/metadata/latest.json")

    local files_json
    files_json=$(printf '"%s",' "${purge_urls[@]}" | sed 's/,$//')

    if curl -fsSL -X POST \
         "https://api.cloudflare.com/client/v4/zones/${cf_zone}/purge_cache" \
         -H "Authorization: Bearer ${cf_token}" \
         -H "Content-Type: application/json" \
         -d "{\"files\": [${files_json}]}" &>/dev/null; then
        log_ok "CDN cache purged for checksums and metadata"
    else
        log_warn "Cache purge failed (non-fatal)"
    fi
}

###############################################################################
# Main
###############################################################################

main() {
    echo -e "${BOLD}24HG — R2 Upload${RESET}"
    echo ""

    preflight
    generate_checksums
    upload_files
    generate_urls
    update_mirror_api
    purge_cdn_cache

    echo ""
    log_ok "All done! ISOs are live on the CDN."
}

main "$@"
