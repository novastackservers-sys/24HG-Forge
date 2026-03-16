#!/bin/bash
# HubOS GameMode End Hook
# Triggered automatically when the last game using GameMode exits.
# Restores all settings to desktop defaults.

# Restore network
/usr/bin/hubos-netguard stop &>/dev/null &

# Restore desktop input (adaptive mouse accel)
/usr/bin/hubos-input desktop &>/dev/null &

# Restore desktop audio (balanced latency)
/usr/bin/hubos-audio desktop &>/dev/null &

# Stop replay buffer
/usr/bin/hubos-replay stop &>/dev/null &

exit 0
