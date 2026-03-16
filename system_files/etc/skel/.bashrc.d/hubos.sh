# HubOS shell customizations
# Sourced by .bashrc on Fedora (via /etc/skel/.bashrc.d/ pattern)

# Show HubOS system info on first terminal open (once per session)
if [ -z "$HUBOS_GREETED" ] && [ -x /usr/bin/hubos-neofetch ]; then
    /usr/bin/hubos-neofetch
    export HUBOS_GREETED=1
fi

# 24HG Quick aliases
alias hub='xdg-open https://hub.24hgaming.com'
alias servers='xdg-open https://hub.24hgaming.com/servers'
alias hubos-update='rpm-ostree upgrade && echo "Reboot to apply: systemctl reboot"'
alias hubos-rollback='rpm-ostree rollback && echo "Reboot to apply: systemctl reboot"'

# Game server quick connect (via Steam protocol)
connect-rust()    { xdg-open "steam://connect/91.99.37.118:27021"; }
connect-cs2()     { xdg-open "steam://connect/91.99.37.118:27015"; }
connect-tf2()     { xdg-open "steam://connect/91.99.37.118:27025"; }

# Gaming environment
export MANGOHUD_CONFIG="position=top-left,fps,gpu_stats,cpu_stats,ram,vram,frame_timing,toggle_hud=F12"
export DXVK_LOG_LEVEL=none
export PROTON_ENABLE_NVAPI=1
export PROTON_HIDE_NVIDIA_GPU=0
