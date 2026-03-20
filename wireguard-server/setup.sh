#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# 24HG Discovery VPN — WireGuard Server Setup
#
# This sets up a discovery-only virtual LAN for 24HG gamers.
# Clients connect to find each other (mDNS/Avahi), exchange real public IPs,
# then game traffic goes direct peer-to-peer. Near-zero bandwidth on server.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/config"
DATA_DIR="${SCRIPT_DIR}/data"
WG_DIR="${CONFIG_DIR}/wg_confs"
SERVER_KEY_DIR="${CONFIG_DIR}/server"

echo "============================================"
echo "  24HG Discovery VPN — WireGuard Setup"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# 1. Install WireGuard tools if not present
# ---------------------------------------------------------------------------
if ! command -v wg &>/dev/null; then
    echo "[*] Installing WireGuard tools..."
    if command -v apt-get &>/dev/null; then
        apt-get update -qq && apt-get install -y -qq wireguard-tools
    elif command -v dnf &>/dev/null; then
        dnf install -y wireguard-tools
    elif command -v pacman &>/dev/null; then
        pacman -Sy --noconfirm wireguard-tools
    else
        echo "[!] Could not detect package manager. Install wireguard-tools manually."
        exit 1
    fi
else
    echo "[*] WireGuard tools already installed."
fi

# ---------------------------------------------------------------------------
# 2. Create directories
# ---------------------------------------------------------------------------
echo "[*] Creating directories..."
mkdir -p "${SERVER_KEY_DIR}" "${WG_DIR}" "${DATA_DIR}"

# ---------------------------------------------------------------------------
# 3. Generate server keys (skip if already exist)
# ---------------------------------------------------------------------------
if [[ -f "${SERVER_KEY_DIR}/privatekey-server" ]]; then
    echo "[*] Server keys already exist, skipping key generation."
else
    echo "[*] Generating server keypair..."
    wg genkey | tee "${SERVER_KEY_DIR}/privatekey-server" | wg pubkey > "${SERVER_KEY_DIR}/publickey-server"
    chmod 600 "${SERVER_KEY_DIR}/privatekey-server"
fi

SERVER_PRIVKEY=$(cat "${SERVER_KEY_DIR}/privatekey-server")
SERVER_PUBKEY=$(cat "${SERVER_KEY_DIR}/publickey-server")

# ---------------------------------------------------------------------------
# 4. Create initial wg0.conf
# ---------------------------------------------------------------------------
echo "[*] Writing wg0.conf..."
cat > "${WG_DIR}/wg0.conf" <<EOF
[Interface]
Address = 10.24.0.1/16
ListenPort = 51820
PrivateKey = ${SERVER_PRIVKEY}

# Discovery-only firewall rules:
# Allow mDNS discovery between clients
PostUp = iptables -A FORWARD -i wg0 -o wg0 -p udp --dport 5353 -j ACCEPT
# Allow Avahi/game discovery port
PostUp = iptables -A FORWARD -i wg0 -o wg0 -p udp --dport 24240 -j ACCEPT
# Allow ICMP (ping for latency testing)
PostUp = iptables -A FORWARD -i wg0 -o wg0 -p icmp -j ACCEPT
# Block everything else between clients (game traffic goes direct)
PostUp = iptables -A FORWARD -i wg0 -o wg0 -j DROP

# Clean up on shutdown
PostDown = iptables -D FORWARD -i wg0 -o wg0 -p udp --dport 5353 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o wg0 -p udp --dport 24240 -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o wg0 -p icmp -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -o wg0 -j DROP

# Peers are managed dynamically by the API — do not add them here.
EOF

chmod 600 "${WG_DIR}/wg0.conf"

# ---------------------------------------------------------------------------
# 5. Verify Docker / Docker Compose
# ---------------------------------------------------------------------------
if ! command -v docker &>/dev/null; then
    echo "[!] Docker is not installed. Please install Docker first."
    exit 1
fi

if docker compose version &>/dev/null; then
    COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
    COMPOSE="docker-compose"
else
    echo "[!] Docker Compose is not installed."
    exit 1
fi

# ---------------------------------------------------------------------------
# 6. Build and start services
# ---------------------------------------------------------------------------
echo "[*] Building and starting containers..."
cd "${SCRIPT_DIR}"
${COMPOSE} up -d --build

echo ""
echo "============================================"
echo "  24HG Discovery VPN is running!"
echo "============================================"
echo ""
echo "  Server Public Key : ${SERVER_PUBKEY}"
echo "  Endpoint          : vpn.24hgaming.com:51820"
echo "  API               : http://localhost:3860/api/vpn/health"
echo "  Subnet            : 10.24.0.0/16"
echo ""
echo "  Traffic policy    : Discovery only (mDNS + port 24240 + ICMP)"
echo "                      Game traffic goes direct peer-to-peer."
echo ""
echo "  Manage peers via the API:"
echo "    POST /api/vpn/join    — Join the discovery network"
echo "    POST /api/vpn/leave   — Leave the network"
echo "    GET  /api/vpn/status  — View all peers"
echo "    GET  /api/vpn/peers   — Online peers only"
echo "    POST /api/vpn/refresh — Rotate keys"
echo ""
