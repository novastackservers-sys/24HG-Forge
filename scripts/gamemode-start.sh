#!/bin/bash
# 24HG Forge GameMode Start Hook
# Triggered automatically when a game launches via GameMode.
# Activates all gaming optimizations.

# Network optimization
/usr/bin/forge-netguard start &>/dev/null &

# Switch to gaming input (flat mouse accel, fast keyboard)
/usr/bin/forge-input gaming &>/dev/null &

# Switch to low-latency audio
/usr/bin/forge-audio gaming &>/dev/null &

# Start replay buffer if gpu-screen-recorder is available
if command -v gpu-screen-recorder &>/dev/null; then
    /usr/bin/forge-replay start &>/dev/null &
fi

exit 0
