#!/bin/bash
# Configure Steam with 24HG community servers in favorites
# Run this after Steam is installed (typically via first-boot Flatpak)
#
# This creates a localconfig.vdf entry for favorite servers

STEAM_DIR="${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam"
CONFIG_DIR="${STEAM_DIR}/config"

# 24HG Server List — all 88+ servers
# Format: IP:PORT (query port)
declare -A SERVERS=(
    # Rust
    ["24HG Rust - No Man's Land"]="91.99.37.118:27021"

    # CS2
    ["24HG CS2 - Competitive"]="91.99.37.118:27015"

    # TF2 Servers (selection)
    ["24HG TF2 - 2Fort"]="91.99.37.118:27025"
    ["24HG TF2 - Dustbowl"]="91.99.37.118:27026"
    ["24HG TF2 - Turbine"]="91.99.37.118:27027"

    # CS 1.6
    ["24HG CS 1.6 - Dust2"]="91.99.37.118:27030"
    ["24HG CS 1.6 - Iceworld"]="91.99.37.118:27031"
)

echo "Configuring 24HG servers in Steam favorites..."

# Wait for Steam config directory to exist
if [ ! -d "${CONFIG_DIR}" ]; then
    echo "Steam config directory not found. Steam may not have been launched yet."
    echo "Run Steam once, then re-run this script."
    exit 0
fi

# Create serverbrowser_hist.vdf with favorites
FAVORITES_FILE="${CONFIG_DIR}/serverbrowser_hist.vdf"

cat > "${FAVORITES_FILE}" << 'HEADER'
"Filters"
{
	"Favorites"
	{
HEADER

INDEX=0
for name in "${!SERVERS[@]}"; do
    addr="${SERVERS[$name]}"
    ip="${addr%:*}"
    port="${addr#*:}"

    cat >> "${FAVORITES_FILE}" << EOF
		"${INDEX}"
		{
			"address"		"${ip}"
			"port"		"${port}"
			"name"		"${name}"
		}
EOF
    INDEX=$((INDEX + 1))
done

cat >> "${FAVORITES_FILE}" << 'FOOTER'
	}
}
FOOTER

echo "Added ${INDEX} servers to Steam favorites."
echo "Restart Steam to see them in the server browser."
