#!/usr/bin/env bash
# 24hg-i18n.sh — Localization library for 24HG scripts
# Source this file: . /usr/lib/24hg/24hg-i18n.sh
# Usage:
#   echo "$(t 'greeting')"
#   echo "$(t 'welcome_user' "$USER")"

HG24_LOCALE_DIR="${HG24_LOCALE_DIR:-/usr/share/24hg/locale}"

# Associative arrays for translations
declare -gA HG24_STRINGS=()
declare -gA HG24_STRINGS_FALLBACK=()

# Detect language from environment
_hg24_detect_lang() {
    local raw="${LC_MESSAGES:-${LANG:-en_US.UTF-8}}"
    # Strip encoding (e.g. en_US.UTF-8 -> en_US)
    raw="${raw%%.*}"
    # Strip modifier (e.g. sr_RS@latin -> sr_RS)
    raw="${raw%%@*}"
    echo "$raw"
}

# Load a locale file into a target array
# Args: $1 = locale code, $2 = array name (HG24_STRINGS or HG24_STRINGS_FALLBACK)
_hg24_load_locale() {
    local lang="$1"
    local target="$2"
    local file=""

    # Try exact match first (e.g. pt_BR), then base language (e.g. pt)
    if [[ -f "${HG24_LOCALE_DIR}/${lang}.sh" ]]; then
        file="${HG24_LOCALE_DIR}/${lang}.sh"
    elif [[ "$lang" == *_* ]] && [[ -f "${HG24_LOCALE_DIR}/${lang%%_*}.sh" ]]; then
        file="${HG24_LOCALE_DIR}/${lang%%_*}.sh"
    fi

    if [[ -n "$file" ]]; then
        # Clear any previous STRINGS array and source the locale file
        unset STRINGS
        declare -gA STRINGS=()
        # shellcheck disable=SC1090
        source "$file"
        local key
        for key in "${!STRINGS[@]}"; do
            if [[ "$target" == "HG24_STRINGS" ]]; then
                HG24_STRINGS["$key"]="${STRINGS[$key]}"
            else
                HG24_STRINGS_FALLBACK["$key"]="${STRINGS[$key]}"
            fi
        done
        unset STRINGS
        return 0
    fi
    return 1
}

# Initialize: load English fallback, then user locale
_hg24_init() {
    local user_lang
    user_lang="$(_hg24_detect_lang)"

    # Always load English as fallback
    _hg24_load_locale "en" "HG24_STRINGS_FALLBACK"

    # Load user locale into primary array (skip if already English)
    if [[ "${user_lang%%_*}" != "en" ]]; then
        _hg24_load_locale "$user_lang" "HG24_STRINGS" || true
    fi
}

# Translate a key with optional printf arguments
# Usage: t "key" [arg1] [arg2] ...
t() {
    local key="$1"
    shift

    local str=""
    # Check user locale first, then fallback
    if [[ -n "${HG24_STRINGS[$key]+set}" ]]; then
        str="${HG24_STRINGS[$key]}"
    elif [[ -n "${HG24_STRINGS_FALLBACK[$key]+set}" ]]; then
        str="${HG24_STRINGS_FALLBACK[$key]}"
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
_hg24_init
