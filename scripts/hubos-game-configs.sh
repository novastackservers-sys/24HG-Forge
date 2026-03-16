#!/bin/bash
# HubOS Game Configuration Deployer
# Drops optimized configs and 24HG server lists for supported games
# Run after Steam first launch to populate game configs

set -euo pipefail

STEAM_DIR="${HOME}/.var/app/com.valvesoftware.Steam/.local/share/Steam"
STEAM_CFG="${STEAM_DIR}/steamapps/common"

echo "=== HubOS Game Config Deployer ==="

# ─── CS 1.6 (AppID 10) ───
CS16_DIR="${STEAM_CFG}/Half-Life/cstrike"
if [ -d "$CS16_DIR" ]; then
    echo "Configuring Counter-Strike 1.6..."

    # Autoexec with optimal settings
    cat > "${CS16_DIR}/autoexec.cfg" << 'EOF'
// HubOS - CS 1.6 Optimized Config
// 24 Hour Gaming — 24hgaming.com

// Network (optimized for 24HG servers)
rate 100000
cl_cmdrate 128
cl_updaterate 128
ex_interp 0

// Video
fps_max 999
gl_vsync 0

// Audio
hisound 1
s_a3d 0
s_eax 0

// HUD
hud_fastswitch 1
cl_crosshair_size small
cl_dynamiccrosshair 0

// Misc
con_color "88 166 255"

echo "24HG config loaded — 24hgaming.com"
EOF

    # Server favorites (userdata)
    mkdir -p "${CS16_DIR}"
    cat > "${CS16_DIR}/favservers.dat" << 'EOF'
"Favorites"
{
    "0"
    {
        "name" "24HG | CS 1.6 | Dust2"
        "address" "91.99.37.118:27030"
    }
    "1"
    {
        "name" "24HG | CS 1.6 | Iceworld"
        "address" "91.99.37.118:27031"
    }
}
EOF
    echo "  CS 1.6 configured"
fi

# ─── CS2 (AppID 730) ───
CS2_DIR="${STEAM_CFG}/Counter-Strike Global Offensive/game/csgo/cfg"
if [ -d "$(dirname "$CS2_DIR")" ]; then
    mkdir -p "$CS2_DIR"
    echo "Configuring CS2..."

    cat > "${CS2_DIR}/autoexec.cfg" << 'EOF'
// HubOS - CS2 Optimized Config
// 24 Hour Gaming — 24hgaming.com

// Network
rate 786432
cl_interp_ratio 1
cl_interp 0

// Performance
fps_max 0
r_fullscreen_gamma 2.2
engine_low_latency_sleep_after_client_tick true

// Audio
snd_voipvolume 0.5
snd_headphone_pan_exponent 1.2

// HUD
cl_crosshairsize 2
cl_crosshairthickness 0.5
cl_crosshairgap -2
cl_crosshaircolor 4
cl_crosshair_sniper_width 1

// Console
con_enable 1

echo "24HG config loaded"
EOF
    echo "  CS2 configured"
fi

# ─── TF2 (AppID 440) ───
TF2_DIR="${STEAM_CFG}/Team Fortress 2/tf/cfg"
if [ -d "$(dirname "$TF2_DIR")" ]; then
    mkdir -p "$TF2_DIR"
    echo "Configuring TF2..."

    cat > "${TF2_DIR}/autoexec.cfg" << 'EOF'
// HubOS - TF2 Optimized Config
// 24 Hour Gaming — 24hgaming.com

// Network
rate 196608
cl_cmdrate 66
cl_updaterate 66
cl_interp 0
cl_interp_ratio 1
cl_lagcompensation 1
cl_pred_optimize 2

// Performance
fps_max 0
mat_queue_mode -1
cl_threaded_bone_setup 1

// Audio
snd_mixahead 0.05

// HUD
hud_fastswitch 1
tf_hud_target_id_disable_floating_health 0

// Misc
cl_autoreload 1
tf_medigun_autoheal 1

echo "24HG config loaded"
EOF
    echo "  TF2 configured"
fi

# ─── Rust (AppID 252490) ───
RUST_DIR="${STEAM_CFG}/Rust/cfg"
if [ -d "$(dirname "$RUST_DIR")" ]; then
    mkdir -p "$RUST_DIR"
    echo "Configuring Rust..."

    cat > "${RUST_DIR}/client.cfg" << 'EOF'
// HubOS - Rust Client Config
// 24 Hour Gaming — No Man's Land — 24hgaming.com

client.connect 91.99.37.118:27021
graphics.chat true
client.pushtotalk true
EOF
    echo "  Rust configured (default server: No Man's Land)"
fi

# ─── Steam Launch Options ───
echo ""
echo "Recommended Steam launch options (set per-game in Steam):"
echo "  All games:     gamemoderun %command%"
echo "  CS2:           gamemoderun %command% -vulkan -high"
echo "  TF2:           gamemoderun %command% -novid -nojoy -nosteamcontroller"
echo "  Rust:          gamemoderun %command% -window-mode exclusive"
echo ""

echo "=== Game configs deployed ==="
