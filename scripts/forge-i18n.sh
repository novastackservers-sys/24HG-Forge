#!/usr/bin/env bash
# forge-i18n.sh — Localization library for 24HG Forge scripts
# Source this file: . /usr/lib/forge/forge-i18n.sh
# Usage:
#   echo "$(t 'greeting')"
#   echo "$(t 'welcome_user' "$USER")"

FORGE_LOCALE_DIR="${FORGE_LOCALE_DIR:-/usr/share/forge/locale}"

# Associative arrays for translations
declare -gA FORGE_STRINGS=()
declare -gA FORGE_STRINGS_FALLBACK=()

# Detect language from environment
_forge_detect_lang() {
    local raw="${LC_MESSAGES:-${LANG:-en_US.UTF-8}}"
    # Strip encoding (e.g. en_US.UTF-8 -> en_US)
    raw="${raw%%.*}"
    # Strip modifier (e.g. sr_RS@latin -> sr_RS)
    raw="${raw%%@*}"
    echo "$raw"
}

# Load a locale file into a target array
# Args: $1 = locale code, $2 = array name (FORGE_STRINGS or FORGE_STRINGS_FALLBACK)
_forge_load_locale() {
    local lang="$1"
    local target="$2"
    local file=""

    # Try exact match first (e.g. pt_BR), then base language (e.g. pt)
    if [[ -f "${FORGE_LOCALE_DIR}/${lang}.sh" ]]; then
        file="${FORGE_LOCALE_DIR}/${lang}.sh"
    elif [[ "$lang" == *_* ]] && [[ -f "${FORGE_LOCALE_DIR}/${lang%%_*}.sh" ]]; then
        file="${FORGE_LOCALE_DIR}/${lang%%_*}.sh"
    fi

    if [[ -n "$file" ]]; then
        # Clear any previous STRINGS array and source the locale file
        unset STRINGS
        declare -gA STRINGS=()
        # shellcheck disable=SC1090
        source "$file"
        local key
        for key in "${!STRINGS[@]}"; do
            if [[ "$target" == "FORGE_STRINGS" ]]; then
                FORGE_STRINGS["$key"]="${STRINGS[$key]}"
            else
                FORGE_STRINGS_FALLBACK["$key"]="${STRINGS[$key]}"
            fi
        done
        unset STRINGS
        return 0
    fi
    return 1
}

# Initialize: load English fallback, then user locale
_forge_init() {
    local user_lang
    user_lang="$(_forge_detect_lang)"

    # Always load English as fallback
    _forge_load_locale "en" "FORGE_STRINGS_FALLBACK"

    # Load user locale into primary array (skip if already English)
    if [[ "${user_lang%%_*}" != "en" ]]; then
        _forge_load_locale "$user_lang" "FORGE_STRINGS" || true
    fi
}

# Translate a key with optional printf arguments
# Usage: t "key" [arg1] [arg2] ...
t() {
    local key="$1"
    shift

    local str=""
    # Check user locale first, then fallback
    if [[ -n "${FORGE_STRINGS[$key]+set}" ]]; then
        str="${FORGE_STRINGS[$key]}"
    elif [[ -n "${FORGE_STRINGS_FALLBACK[$key]+set}" ]]; then
        str="${FORGE_STRINGS_FALLBACK[$key]}"
    else
        # Key not found anywhere — return the key itself
        str="$key"
    fi

    if [[ $# -gt 0 ]]; then
        # shellcheck disable=SC2059
        printf "$str" "$@"
    else
        printf '%s' "$str"
    fi
}

# Run initialization on source
_forge_init
