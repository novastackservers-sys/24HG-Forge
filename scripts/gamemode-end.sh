#!/bin/bash
# 24HG Forge GameMode End Hook
# Triggered automatically when the last game using GameMode exits.
# Restores all settings to desktop defaults.

# Restore network
/usr/bin/forge-netguard stop &>/dev/null &

# Restore desktop input (adaptive mouse accel)
/usr/bin/forge-input desktop &>/dev/null &

# Restore desktop audio (balanced latency)
/usr/bin/forge-audio desktop &>/dev/null &

# Stop replay buffer
/usr/bin/forge-replay stop &>/dev/null &

exit 0
