"""
24HG WireGuard Discovery VPN — Peer Management API

This API manages WireGuard peers for a discovery-only virtual LAN.
Clients connect to find each other via mDNS/Avahi, exchange real public IPs,
then game traffic goes direct peer-to-peer. Only tiny discovery packets
traverse the VPN tunnel.

Port: 3860
"""

import os
import sqlite3
import subprocess
import time
from datetime import datetime, timezone
from functools import wraps
from pathlib import Path

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
DB_PATH = os.getenv("DB_PATH", "/data/peers.db")
WG_CONFIG_DIR = os.getenv("WG_CONFIG_DIR", "/config")
HUB_VALIDATE_URL = os.getenv(
    "HUB_VALIDATE_URL", "https://api.24hgaming.com/auth/validate"
)
WG_INTERFACE = "wg0"
SUBNET_PREFIX = "10.24"  # 10.24.0.0/16
SERVER_IP = f"{SUBNET_PREFIX}.0.1"
# Assignable range: 10.24.1.1 — 10.24.255.254
IP_RANGE_START = (1, 1)  # (third_octet, fourth_octet)
IP_RANGE_END = (255, 254)

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------


def get_db():
    """Return a connection to the SQLite database."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


def init_db():
    """Create tables if they don't exist."""
    conn = get_db()
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS peers (
            id            INTEGER PRIMARY KEY AUTOINCREMENT,
            username      TEXT    NOT NULL,
            hub_user_id   TEXT    NOT NULL UNIQUE,
            public_key    TEXT    NOT NULL,
            private_key   TEXT    NOT NULL,
            assigned_ip   TEXT    NOT NULL UNIQUE,
            created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
            last_seen     TEXT
        )
    """
    )
    conn.commit()
    conn.close()


# ---------------------------------------------------------------------------
# WireGuard helpers
# ---------------------------------------------------------------------------


def wg_genkey():
    """Generate a WireGuard private key and derive the public key."""
    privkey = subprocess.check_output(["wg", "genkey"]).decode().strip()
    pubkey = subprocess.check_output(
        ["wg", "pubkey"], input=privkey.encode()
    ).decode().strip()
    return privkey, pubkey


def wg_add_peer(pubkey: str, allowed_ip: str):
    """Add a peer to the live WireGuard interface."""
    subprocess.run(
        ["wg", "set", WG_INTERFACE, "peer", pubkey, "allowed-ips", f"{allowed_ip}/32"],
        check=True,
    )


def wg_remove_peer(pubkey: str):
    """Remove a peer from the live WireGuard interface."""
    subprocess.run(
        ["wg", "set", WG_INTERFACE, "peer", pubkey, "remove"],
        check=True,
    )


def wg_get_handshakes() -> dict:
    """Return a dict of pubkey -> latest_handshake_epoch from `wg show`."""
    try:
        output = subprocess.check_output(
            ["wg", "show", WG_INTERFACE, "latest-handshakes"]
        ).decode()
    except subprocess.CalledProcessError:
        return {}

    handshakes = {}
    for line in output.strip().splitlines():
        parts = line.split("\t")
        if len(parts) == 2:
            pubkey, ts = parts
            handshakes[pubkey] = int(ts)
    return handshakes


def get_server_public_key() -> str:
    """Read the server's public key from the WireGuard config."""
    try:
        output = subprocess.check_output(
            ["wg", "show", WG_INTERFACE, "public-key"]
        ).decode().strip()
        return output
    except subprocess.CalledProcessError:
        # Fallback: read from config file
        pubkey_path = Path(WG_CONFIG_DIR) / "server" / "publickey-server"
        if pubkey_path.exists():
            return pubkey_path.read_text().strip()
        return ""


# ---------------------------------------------------------------------------
# IP allocation
# ---------------------------------------------------------------------------


def next_available_ip(conn) -> str | None:
    """Find the next unused IP in 10.24.1.1 — 10.24.255.254."""
    used = {row["assigned_ip"] for row in conn.execute("SELECT assigned_ip FROM peers")}

    for third in range(IP_RANGE_START[0], IP_RANGE_END[0] + 1):
        start_fourth = IP_RANGE_START[1] if third == IP_RANGE_START[0] else 1
        end_fourth = IP_RANGE_END[1] if third == IP_RANGE_END[0] else 254
        for fourth in range(start_fourth, end_fourth + 1):
            ip = f"{SUBNET_PREFIX}.{third}.{fourth}"
            if ip not in used:
                return ip
    return None


# ---------------------------------------------------------------------------
# Auth middleware
# ---------------------------------------------------------------------------


def require_auth(f):
    """Validate the Hub JWT token via the Hub API."""

    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Missing or invalid Authorization header"}), 401

        token = auth_header[7:]
        try:
            resp = requests.post(
                HUB_VALIDATE_URL,
                json={"token": token},
                timeout=10,
            )
            if resp.status_code != 200:
                return jsonify({"error": "Token validation failed"}), 401

            user_data = resp.json()
            if not user_data.get("valid"):
                return jsonify({"error": "Invalid token"}), 401

            request.hub_user = user_data
        except requests.RequestException:
            return jsonify({"error": "Auth service unavailable"}), 503

        return f(*args, **kwargs)

    return decorated


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.route("/api/vpn/join", methods=["POST"])
@require_auth
def join():
    """Generate a WireGuard peer config, add the peer to the server."""
    user = request.hub_user
    hub_user_id = str(user.get("user_id", user.get("id", "")))
    username = user.get("username", "unknown")

    if not hub_user_id:
        return jsonify({"error": "Could not determine user ID from token"}), 400

    conn = get_db()

    # Check if user already has a peer (rate limit: 1 per user)
    existing = conn.execute(
        "SELECT * FROM peers WHERE hub_user_id = ?", (hub_user_id,)
    ).fetchone()
    if existing:
        conn.close()
        return jsonify({"error": "You already have a VPN peer. Use /api/vpn/refresh to get new keys or /api/vpn/leave to disconnect first."}), 409

    # Allocate IP
    assigned_ip = next_available_ip(conn)
    if not assigned_ip:
        conn.close()
        return jsonify({"error": "No IPs available — subnet exhausted"}), 503

    # Generate keypair
    privkey, pubkey = wg_genkey()

    # Store in DB
    conn.execute(
        """
        INSERT INTO peers (username, hub_user_id, public_key, private_key, assigned_ip, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (username, hub_user_id, pubkey, privkey, assigned_ip, datetime.now(timezone.utc).isoformat()),
    )
    conn.commit()
    conn.close()

    # Add to live WireGuard interface
    try:
        wg_add_peer(pubkey, assigned_ip)
    except subprocess.CalledProcessError as exc:
        # Rollback DB entry on failure
        conn2 = get_db()
        conn2.execute("DELETE FROM peers WHERE hub_user_id = ?", (hub_user_id,))
        conn2.commit()
        conn2.close()
        return jsonify({"error": "Failed to add WireGuard peer"}), 500

    # Get server details for client config
    server_pubkey = get_server_public_key()

    # Build client config
    client_config = f"""[Interface]
PrivateKey = {privkey}
Address = {assigned_ip}/16

[Peer]
PublicKey = {server_pubkey}
Endpoint = vpn.24hgaming.com:51820
AllowedIPs = 10.24.0.0/16
PersistentKeepalive = 25
"""

    return jsonify({
        "message": f"Welcome to 24HG Discovery VPN, {username}!",
        "assigned_ip": assigned_ip,
        "private_key": privkey,
        "server_public_key": server_pubkey,
        "config": client_config,
        "note": "Only discovery/mDNS traffic goes through VPN. Game traffic goes direct peer-to-peer.",
    }), 201


@app.route("/api/vpn/leave", methods=["POST"])
@require_auth
def leave():
    """Remove the authenticated user's peer from the server."""
    user = request.hub_user
    hub_user_id = str(user.get("user_id", user.get("id", "")))

    conn = get_db()
    peer = conn.execute(
        "SELECT * FROM peers WHERE hub_user_id = ?", (hub_user_id,)
    ).fetchone()

    if not peer:
        conn.close()
        return jsonify({"error": "You don't have an active VPN peer"}), 404

    # Remove from WireGuard
    try:
        wg_remove_peer(peer["public_key"])
    except subprocess.CalledProcessError:
        pass  # Best effort — peer may already be gone

    # Remove from DB
    conn.execute("DELETE FROM peers WHERE hub_user_id = ?", (hub_user_id,))
    conn.commit()
    conn.close()

    return jsonify({"message": "VPN peer removed. You have left the discovery network."})


@app.route("/api/vpn/status", methods=["GET"])
@require_auth
def status():
    """Show connected peers with last handshake times."""
    conn = get_db()
    peers = conn.execute("SELECT username, assigned_ip, public_key, last_seen FROM peers").fetchall()
    conn.close()

    handshakes = wg_get_handshakes()
    now = int(time.time())

    result = []
    for p in peers:
        last_handshake = handshakes.get(p["public_key"], 0)
        online = (now - last_handshake) < 180 if last_handshake > 0 else False
        result.append({
            "username": p["username"],
            "ip": p["assigned_ip"],
            "online": online,
            "last_handshake": datetime.fromtimestamp(last_handshake, tz=timezone.utc).isoformat() if last_handshake > 0 else None,
        })

    return jsonify({
        "total_peers": len(result),
        "online": sum(1 for r in result if r["online"]),
        "peers": result,
    })


@app.route("/api/vpn/peers", methods=["GET"])
@require_auth
def peers():
    """List all online peers with their 24HG usernames."""
    conn = get_db()
    all_peers = conn.execute("SELECT username, assigned_ip, public_key FROM peers").fetchall()
    conn.close()

    handshakes = wg_get_handshakes()
    now = int(time.time())

    online_peers = []
    for p in all_peers:
        last_handshake = handshakes.get(p["public_key"], 0)
        if last_handshake > 0 and (now - last_handshake) < 180:
            online_peers.append({
                "username": p["username"],
                "ip": p["assigned_ip"],
            })

    return jsonify({
        "online_count": len(online_peers),
        "peers": online_peers,
    })


@app.route("/api/vpn/refresh", methods=["POST"])
@require_auth
def refresh():
    """Refresh peer config with new keys. Keeps the same IP."""
    user = request.hub_user
    hub_user_id = str(user.get("user_id", user.get("id", "")))

    conn = get_db()
    peer = conn.execute(
        "SELECT * FROM peers WHERE hub_user_id = ?", (hub_user_id,)
    ).fetchone()

    if not peer:
        conn.close()
        return jsonify({"error": "You don't have an active VPN peer. Use /api/vpn/join first."}), 404

    old_pubkey = peer["public_key"]
    assigned_ip = peer["assigned_ip"]
    username = peer["username"]

    # Generate new keypair
    new_privkey, new_pubkey = wg_genkey()

    # Remove old peer, add new one
    try:
        wg_remove_peer(old_pubkey)
    except subprocess.CalledProcessError:
        pass

    try:
        wg_add_peer(new_pubkey, assigned_ip)
    except subprocess.CalledProcessError as exc:
        # Re-add old peer on failure
        try:
            wg_add_peer(old_pubkey, assigned_ip)
        except subprocess.CalledProcessError:
            pass
        conn.close()
        return jsonify({"error": "Failed to refresh peer"}), 500

    # Update DB
    conn.execute(
        "UPDATE peers SET public_key = ?, private_key = ? WHERE hub_user_id = ?",
        (new_pubkey, new_privkey, hub_user_id),
    )
    conn.commit()
    conn.close()

    server_pubkey = get_server_public_key()

    client_config = f"""[Interface]
PrivateKey = {new_privkey}
Address = {assigned_ip}/16

[Peer]
PublicKey = {server_pubkey}
Endpoint = vpn.24hgaming.com:51820
AllowedIPs = 10.24.0.0/16
PersistentKeepalive = 25
"""

    return jsonify({
        "message": f"Keys refreshed for {username}. Update your WireGuard client config.",
        "assigned_ip": assigned_ip,
        "private_key": new_privkey,
        "server_public_key": server_pubkey,
        "config": client_config,
    })


@app.route("/api/vpn/health", methods=["GET"])
def health():
    """Health check endpoint (no auth required)."""
    try:
        subprocess.check_output(["wg", "show", WG_INTERFACE], stderr=subprocess.DEVNULL)
        wg_up = True
    except (subprocess.CalledProcessError, FileNotFoundError):
        wg_up = False

    return jsonify({
        "status": "ok" if wg_up else "degraded",
        "wireguard": "up" if wg_up else "down",
        "service": "24HG Discovery VPN",
    })


# ---------------------------------------------------------------------------
# Admin Endpoints (for Control Room)
# ---------------------------------------------------------------------------


def require_admin(f):
    """Validate the Hub JWT and check for admin role."""

    @wraps(f)
    def decorated(*args, **kwargs):
        auth_header = request.headers.get("Authorization", "")
        if not auth_header.startswith("Bearer "):
            return jsonify({"error": "Missing or invalid Authorization header"}), 401

        token = auth_header[7:]
        try:
            resp = requests.post(
                HUB_VALIDATE_URL,
                json={"token": token},
                timeout=10,
            )
            if resp.status_code != 200:
                return jsonify({"error": "Token validation failed"}), 401

            user_data = resp.json()
            if not user_data.get("valid"):
                return jsonify({"error": "Invalid token"}), 401
            if user_data.get("role") not in ("admin", "superadmin"):
                return jsonify({"error": "Admin access required"}), 403

            request.hub_user = user_data
        except requests.RequestException:
            return jsonify({"error": "Auth service unavailable"}), 503

        return f(*args, **kwargs)

    return decorated


@app.route("/api/vpn/admin/add", methods=["POST"])
@require_admin
def admin_add():
    """Admin: create a VPN peer for any username."""
    data = request.get_json() or {}
    username = data.get("username", "").strip()
    if not username:
        return jsonify({"error": "Username is required"}), 400

    conn = get_db()

    # Check if user already has a peer
    existing = conn.execute(
        "SELECT * FROM peers WHERE username = ?", (username,)
    ).fetchone()
    if existing:
        conn.close()
        return jsonify({"error": f"{username} already has a VPN peer (IP: {existing['assigned_ip']})"}), 409

    # Allocate IP
    assigned_ip = next_available_ip(conn)
    if not assigned_ip:
        conn.close()
        return jsonify({"error": "No IPs available"}), 503

    # Generate keypair
    privkey, pubkey = wg_genkey()

    # Store in DB (use username as hub_user_id for admin-created peers)
    conn.execute(
        """
        INSERT INTO peers (username, hub_user_id, public_key, private_key, assigned_ip, created_at)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (username, f"admin:{username}", pubkey, privkey, assigned_ip, datetime.now(timezone.utc).isoformat()),
    )
    conn.commit()
    conn.close()

    # Add to live WireGuard interface
    try:
        wg_add_peer(pubkey, assigned_ip)
    except subprocess.CalledProcessError:
        conn2 = get_db()
        conn2.execute("DELETE FROM peers WHERE hub_user_id = ?", (f"admin:{username}",))
        conn2.commit()
        conn2.close()
        return jsonify({"error": "Failed to add WireGuard peer"}), 500

    server_pubkey = get_server_public_key()

    client_config = f"""[Interface]
PrivateKey = {privkey}
Address = {assigned_ip}/16

[Peer]
PublicKey = {server_pubkey}
Endpoint = vpn.24hgaming.com:51820
AllowedIPs = 10.24.0.0/16
PersistentKeepalive = 25
"""

    return jsonify({
        "message": f"Peer created for {username}",
        "assigned_ip": assigned_ip,
        "private_key": privkey,
        "server_public_key": server_pubkey,
        "config": client_config,
    }), 201


@app.route("/api/vpn/admin/remove", methods=["POST"])
@require_admin
def admin_remove():
    """Admin: remove a VPN peer by username."""
    data = request.get_json() or {}
    username = data.get("username", "").strip()
    if not username:
        return jsonify({"error": "Username is required"}), 400

    conn = get_db()
    peer = conn.execute(
        "SELECT * FROM peers WHERE username = ?", (username,)
    ).fetchone()

    if not peer:
        conn.close()
        return jsonify({"error": f"No VPN peer found for {username}"}), 404

    # Remove from WireGuard
    try:
        wg_remove_peer(peer["public_key"])
    except subprocess.CalledProcessError:
        pass

    # Remove from DB
    conn.execute("DELETE FROM peers WHERE username = ?", (username,))
    conn.commit()
    conn.close()

    return jsonify({"message": f"Peer {username} removed"})


# ---------------------------------------------------------------------------
# Startup
# ---------------------------------------------------------------------------

# Initialize DB at import time so gunicorn workers have the table ready.
init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=3860, debug=False)
