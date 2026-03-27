#!/bin/bash
# 24HG GameMode Start Hook
# Triggered automatically when a game launches via GameMode.
# Activates all gaming optimizations.

# Network optimization
/usr/bin/24hg-netguard start &>/dev/null &

# Switch to gaming input (flat mouse accel, fast keyboard)
/usr/bin/24hg-input gaming &>/dev/null &

# Switch to low-latency audio
/usr/bin/24hg-audio gaming &>/dev/null &

# Start replay buffer if gpu-screen-recorder is available
if command -v gpu-screen-recorder &>/dev/null; then
    /usr/bin/24hg-replay start &>/dev/null &
fi

exit 0
