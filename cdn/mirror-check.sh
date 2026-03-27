#!/usr/bin/env bash
set -euo pipefail
# 24HG — Mirror Health Checker (cron: 0 */6 * * *)
#
# Checks all registered mirrors for:
#   - HTTP availability
#   - ISO checksum integrity
#   - Response time
# Reports dead/stale mirrors to the API.

###############################################################################
# Configuration
###############################################################################
readonly API_BASE="https://os.24hgaming.com/api"
readonly API_KEY="${HG24_API_KEY:-}"
readonly CONNECT_TIMEOUT=10
readonly MAX_TIMEOUT=30
readonly LOG_FILE="/var/log/24hg-mirror-check.log"
readonly TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

###############################################################################
# Logging
###############################################################################

timestamp() { date -Iseconds; }

log() {
    local level="$1"; shift
    local msg="[$(timestamp)] [$level] $*"
    echo "$msg"
    if [[ -w "$(dirname "$LOG_FILE")" ]] || [[ -w "$LOG_FILE" ]]; then
        echo "$msg" >> "$LOG_FILE" 2>/dev/null || true
    fi
}

log_info()  { log "INFO" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_err()   { log "ERROR" "$@"; }
log_ok()    { log "OK" "$@"; }

###############################################################################
# Fetch official checksums
###############################################################################

fetch_official_checksums() {
    log_info "Fetching official checksums..."
    if curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIMEOUT" \
         "${API_BASE}/checksums" -o "${TMP_DIR}/official_sums.txt" 2>/dev/null; then
        log_ok "Got official checksums"
        return 0
    fi

    # Fallback: fetch from CDN directly
    if curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIMEOUT" \
         "https://cdn.24hgaming.com/iso/SHA256SUMS" -o "${TMP_DIR}/official_sums.txt" 2>/dev/null; then
        log_ok "Got official checksums from CDN"
        return 0
    fi

    log_err "Cannot fetch official checksums"
    return 1
}

###############################################################################
# Fetch mirror list
###############################################################################

fetch_mirrors() {
    if ! command -v jq &>/dev/null; then
        log_err "jq is required but not installed"
        exit 1
    fi

    log_info "Fetching mirror list..."
    if ! curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIMEOUT" \
         "${API_BASE}/mirrors" -o "${TMP_DIR}/mirrors.json" 2>/dev/null; then
        log_err "Cannot fetch mirror list"
        exit 1
    fi

    local count
    count=$(jq '.mirrors | length' "${TMP_DIR}/mirrors.json")
    log_info "Found ${count} mirrors to check"
}

###############################################################################
# Check a single mirror
###############################################################################

check_mirror() {
    local url="$1" name="$2" id="$3"
    local status="healthy"
    local latency=-1
    local checksum_ok="false"
    local details=""

    # 1. HTTP availability (HEAD request)
    local start end
    start=$(date +%s%N)
    if curl -fsSL --head --connect-timeout "$CONNECT_TIMEOUT" \
         --max-time "$MAX_TIMEOUT" "${url}/" &>/dev/null; then
        end=$(date +%s%N)
        latency=$(( (end - start) / 1000000 ))
        log_info "  ${name}: responded in ${latency}ms"
    else
        log_warn "  ${name}: OFFLINE (no response)"
        report_status "$id" "offline" -1 "false" "No HTTP response"
        return 1
    fi

    # 2. Check if ISO listing is accessible
    if ! curl -fsSL --head --connect-timeout "$CONNECT_TIMEOUT" \
         --max-time "$MAX_TIMEOUT" "${url}/iso/" &>/dev/null; then
        log_warn "  ${name}: /iso/ path not accessible"
        status="degraded"
        details="ISO directory not accessible"
    fi

    # 3. Verify checksum file matches official
    if [[ -f "${TMP_DIR}/official_sums.txt" ]]; then
        if curl -fsSL --connect-timeout "$CONNECT_TIMEOUT" --max-time "$MAX_TIMEOUT" \
             "${url}/iso/SHA256SUMS" -o "${TMP_DIR}/mirror_sums_${id}.txt" 2>/dev/null; then
            if diff -q "${TMP_DIR}/official_sums.txt" "${TMP_DIR}/mirror_sums_${id}.txt" &>/dev/null; then
                checksum_ok="true"
                log_ok "  ${name}: checksums match"
            else
                log_warn "  ${name}: CHECKSUM MISMATCH"
                status="stale"
                details="Checksum file does not match official release"
            fi
        else
            log_warn "  ${name}: SHA256SUMS not available"
            status="degraded"
            details="${details:+${details}; }Checksum file missing"
        fi
    fi

    # 4. Latency threshold check
    if (( latency > 5000 )); then
        status="degraded"
        details="${details:+${details}; }High latency (${latency}ms)"
    fi

    report_status "$id" "$status" "$latency" "$checksum_ok" "$details"
}

###############################################################################
# Report mirror status to API
###############################################################################

report_status() {
    local mirror_id="$1"
    local status="$2"
    local latency="$3"
    local checksum_ok="$4"
    local details="${5:-}"

    # Append to results for summary
    echo "${mirror_id}|${status}|${latency}|${checksum_ok}|${details}" >> "${TMP_DIR}/results.txt"

    # Report to API if key is set
    if [[ -n "$API_KEY" ]]; then
        local payload
        payload=$(cat <<JSON
{
    "mirror_id": "${mirror_id}",
    "status": "${status}",
    "latency_ms": ${latency},
    "checksum_valid": ${checksum_ok},
    "details": "${details}",
    "checked_at": "$(timestamp)"
}
JSON
        )

        curl -fsSL -X POST "${API_BASE}/mirrors/${mirror_id}/health" \
            -H "Authorization: Bearer ${API_KEY}" \
            -H "Content-Type: application/json" \
            -d "$payload" &>/dev/null || log_warn "Failed to report status for ${mirror_id}"
    fi
}

###############################################################################
# Summary
###############################################################################

print_summary() {
    local results_file="${TMP_DIR}/results.txt"
    [[ -f "$results_file" ]] || return

    local total healthy degraded stale offline
    total=$(wc -l < "$results_file")
    healthy=$(grep -c '|healthy|' "$results_file" || echo 0)
    degraded=$(grep -c '|degraded|' "$results_file" || echo 0)
    stale=$(grep -c '|stale|' "$results_file" || echo 0)
    offline=$(grep -c '|offline|' "$results_file" || echo 0)

    echo ""
    log_info "=== Mirror Health Summary ==="
    log_info "Total:    ${total}"
    log_info "Healthy:  ${healthy}"
    log_info "Degraded: ${degraded}"
    log_info "Stale:    ${stale}"
    log_info "Offline:  ${offline}"

    if (( offline > 0 )); then
        echo ""
        log_warn "Offline mirrors:"
        grep '|offline|' "$results_file" | while IFS='|' read -r mid _ _ _ details; do
            log_warn "  - ${mid}: ${details}"
        done
    fi

    if (( stale > 0 )); then
        echo ""
        log_warn "Stale mirrors (checksum mismatch):"
        grep '|stale|' "$results_file" | while IFS='|' read -r mid _ _ _ details; do
            log_warn "  - ${mid}: ${details}"
        done
    fi
}

###############################################################################
# Main
###############################################################################

main() {
    log_info "=== 24HG Mirror Health Check ==="
    log_info "Started at $(timestamp)"

    touch "${TMP_DIR}/results.txt"

    fetch_official_checksums || true
    fetch_mirrors

    # Check each mirror
    jq -r '.mirrors[] | "\(.url)|\(.name)|\(.id)"' "${TMP_DIR}/mirrors.json" | \
    while IFS='|' read -r url name id; do
        check_mirror "$url" "$name" "$id" || true
    done

    print_summary

    log_info "Finished at $(timestamp)"
}

main "$@"
