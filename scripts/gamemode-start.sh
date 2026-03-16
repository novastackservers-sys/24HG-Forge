#!/bin/bash
# HubOS GameMode Start Hook
# Triggered automatically when a game launches via GameMode.
# Activates all gaming optimizations.

# Network optimization
/usr/bin/hubos-netguard start &>/dev/null &

# Switch to gaming input (flat mouse accel, fast keyboard)
/usr/bin/hubos-input gaming &>/dev/null &

# Switch to low-latency audio
/usr/bin/hubos-audio gaming &>/dev/null &

# Start replay buffer if gpu-screen-recorder is available
if command -v gpu-screen-recorder &>/dev/null; then
    /usr/bin/hubos-replay start &>/dev/null &
fi

exit 0
