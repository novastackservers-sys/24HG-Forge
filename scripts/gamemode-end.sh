#!/bin/bash
# 24HG GameMode End Hook
# Triggered automatically when the last game using GameMode exits.
# Restores all settings to desktop defaults.

# Restore network
/usr/bin/24hg-netguard stop &>/dev/null &

# Restore desktop input (adaptive mouse accel)
/usr/bin/24hg-input desktop &>/dev/null &

# Restore desktop audio (balanced latency)
/usr/bin/24hg-audio desktop &>/dev/null &

# Stop replay buffer
/usr/bin/24hg-replay stop &>/dev/null &

exit 0
