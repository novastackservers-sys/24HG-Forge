#!/bin/bash
# 24HG OBS Studio Setup — Pre-configure OBS for game streaming
# Installs OBS Flatpak and deploys 24HG streaming scene collection

set -euo pipefail

echo "=== 24HG OBS Studio Setup ==="

# Install OBS if not present
if ! flatpak list --app 2>/dev/null | grep -q com.obsproject.Studio; then
    echo "Installing OBS Studio..."
    flatpak install -y --noninteractive flathub com.obsproject.Studio
fi

OBS_DIR="${HOME}/.var/app/com.obsproject.Studio/config/obs-studio"
SCENES_DIR="${OBS_DIR}/basic/scenes"
PROFILES_DIR="${OBS_DIR}/basic/profiles"

mkdir -p "${SCENES_DIR}" "${PROFILES_DIR}/24HG Streaming"

# Create 24HG scene collection
cat > "${SCENES_DIR}/24HG Gaming.json" << 'SCENE_EOF'
{
    "name": "24HG Gaming",
    "current_scene": "Gaming",
    "current_program_scene": "Gaming",
    "sources": [
        {
            "name": "Game Capture",
            "id": "pipewire-screen-capture-source",
            "settings": {
                "ShowCursor": true,
                "RestoreToken": "",
                "CaptureType": 1
            }
        },
        {
            "name": "Webcam",
            "id": "v4l2_input",
            "settings": {
                "device_id": "auto",
                "resolution": "1280x720",
                "frame_rate": 30
            },
            "flags": 0
        },
        {
            "name": "Mic",
            "id": "pulse_input_capture",
            "settings": {
                "device_id": "default"
            }
        },
        {
            "name": "Desktop Audio",
            "id": "pulse_output_capture",
            "settings": {
                "device_id": "default"
            }
        },
        {
            "name": "24HG Overlay",
            "id": "browser_source",
            "settings": {
                "url": "https://hub.24hgaming.com/overlay/stream",
                "width": 400,
                "height": 120,
                "css": "body { background: transparent; }"
            }
        },
        {
            "name": "24HG Watermark",
            "id": "image_source",
            "settings": {
                "file": "/usr/share/icons/24hg/24hg-logo-64.png"
            }
        }
    ],
    "scenes": [
        {
            "name": "Gaming",
            "items": [
                { "name": "Game Capture", "pos": {"x": 0, "y": 0}, "scale": {"x": 1, "y": 1} },
                { "name": "Webcam", "pos": {"x": 1540, "y": 820}, "scale": {"x": 0.25, "y": 0.25}, "bounds_type": 1 },
                { "name": "24HG Watermark", "pos": {"x": 20, "y": 20}, "scale": {"x": 0.5, "y": 0.5} },
                { "name": "24HG Overlay", "pos": {"x": 1520, "y": 20} }
            ]
        },
        {
            "name": "Starting Soon",
            "items": [
                { "name": "24HG Watermark", "pos": {"x": 860, "y": 440}, "scale": {"x": 2, "y": 2} }
            ]
        },
        {
            "name": "BRB",
            "items": [
                { "name": "24HG Watermark", "pos": {"x": 860, "y": 440}, "scale": {"x": 2, "y": 2} }
            ]
        }
    ]
}
SCENE_EOF

# Create streaming profile
cat > "${PROFILES_DIR}/24HG Streaming/basic.ini" << 'PROFILE_EOF'
[General]
Name=24HG Streaming

[Video]
BaseCX=1920
BaseCY=1080
OutputCX=1920
OutputCY=1080
FPSType=0
FPSCommon=60

[Output]
Mode=Advanced

[AdvOut]
TrackIndex=1
RecType=Standard
RecFormat=mkv
RecEncoder=obs_x264
StreamEncoder=obs_x264
FFOutputToFile=true
RescaleRes=1920x1080

[AdvOut.Streaming]
Encoder=obs_x264
x264opts=
Bitrate=6000
KeyframeIntervalSec=2
Preset=veryfast
Profile=high
Tune=zerolatency

[AdvOut.Recording]
RecFilePath=\$HOME/Videos/
RecFormat2=mkv
RecEncoder=obs_x264
RecMuxerCustom=
RecSplitFileType=Time
RecSplitFileTime=60
Bitrate=15000
Preset=fast
PROFILE_EOF

echo "OBS Studio configured with 24HG scenes and streaming profile."
echo ""
echo "Scenes:"
echo "  - Gaming: Game capture + webcam + 24HG overlay"
echo "  - Starting Soon: 24HG logo"
echo "  - BRB: 24HG logo"
echo ""
echo "Profile: 1080p60, 6000kbps (streaming), 15000kbps (recording)"
