# 24HG — Bash Tab Completions
# Provides tab completion for all 24hg-* commands and their subcommands.
# Sourced automatically by bash-completion from /etc/bash_completion.d/

# ---------------------------------------------------------------------------
# All 24hg-* commands (for prefix completion)
# ---------------------------------------------------------------------------
_24HG_ALL_COMMANDS="
24hg-a11y
24hg-achievements
24hg-ai
24hg-anticheat-tracker
24hg-audio
24hg-audio-router
24hg-backup
24hg-benchmark
24hg-benchmark-compare
24hg-boot-select
24hg-boot-speed
24hg-challenges
24hg-cleaner
24hg-clip
24hg-cloud-saves
24hg-compat
24hg-controller
24hg-controllers
24hg-crash-fix
24hg-crash-report
24hg-creator-kit
24hg-custom-res
24hg-deals
24hg-demo
24hg-digest
24hg-discord-rpc
24hg-discord-screen
24hg-display
24hg-download-mgr
24hg-driver-mgr
24hg-dualboot
24hg-dual-gpu
24hg-feed
24hg-firewall
24hg-flatpak-fix
24hg-focus
24hg-gallery
24hg-game-backup
24hg-game-compat
24hg-gamedrive
24hg-game-installer
24hg-game-migrate
24hg-game-profiles
24hg-game-ready
24hg-games
24hg-game-setup
24hg-game-timer
24hg-go-live
24hg-hdr
24hg-help
24hg-highlights
24hg-host
24hg-hub-bridge
24hg-hw-optimizer
24hg-hw-scout
24hg-input-lag
24hg-invite
24hg-lan-mode
24hg-lan-party
24hg-laptop
24hg-launch
24hg-live-wallpaper
24hg-migrate
24hg-mirror
24hg-mod-manager
24hg-mods
24hg-nas
24hg-neofetch
24hg-netguard
24hg-net-optimizer
24hg-nightlight
24hg-notify
24hg-nvidia-wayland
24hg-one-click-server
24hg-overlay
24hg-parental
24hg-perflog
24hg-performance
24hg-perf-profiles
24hg-peripherals
24hg-perks
24hg-ping-optimizer
24hg-power-plan
24hg-prefix
24hg-proton-fix
24hg-proton-pick
24hg-proton-updater
24hg-quick-resume
24hg-radio
24hg-record
24hg-replay
24hg-rescue
24hg-retro
24hg-rig-score
24hg-rollback
24hg-sandbox
24hg-save-manager
24hg-screenshot
24hg-server-status
24hg-session-summary
24hg-settings
24hg-shader-cache
24hg-smart-updates
24hg-snapshot
24hg-sounds
24hg-splitscreen
24hg-stream
24hg-sunshine-setup
24hg-themes
24hg-thermal
24hg-tips
24hg-tour
24hg-tournament
24hg-tray-dashboard
24hg-update
24hg-update-guard
24hg-voice
24hg-vpn
24hg-vr
24hg-wallpaper
24hg-windows-import
"

# ---------------------------------------------------------------------------
# Subcommand completions for major tools
# ---------------------------------------------------------------------------

# Wave 19 — Smart Gaming OS
complete -W "scan optimize status list reset watch"                          24hg-game-ready
complete -W "check apply schedule defer status rollback"                     24hg-smart-updates
complete -W "save restore list delete"                                       24hg-quick-resume
complete -W "scan report monitor alerts history status"                      24hg-hw-scout
complete -W "install search list update remove"                              24hg-game-installer
complete -W "start stop status discover chat vote peers"                     24hg-lan-mode
complete -W "list apply create edit delete auto"                             24hg-perf-profiles
complete -W "desktop game gamemode toggle status"                            24hg-boot-select
complete -W "status update rollback switch health"                           24hg-driver-mgr
complete -W "scan optimize test reset status ping dns"                       24hg-net-optimizer
complete -W "scan migrate verify list"                                       24hg-game-migrate
complete -W "run list allow deny status"                                     24hg-sandbox
complete -W "gaming balanced powersave battery performance auto status"      24hg-power-plan
complete -W "start stop list status logs invite"                             24hg-one-click-server

# Wave 20 — Hardware Control + Polish
complete -W "scan configure profiles rgb dpi macro list mouse"              24hg-peripherals
complete -W "test optimize report reset status"                             24hg-input-lag
complete -W "list route reset profiles save load devices status"            24hg-audio-router
complete -W "scan clean schedule whitelist"                                  24hg-cleaner
complete -W "status switch auto force-dgpu force-igpu run"                  24hg-dual-gpu
complete -W "install remove list update enable disable"                      24hg-mod-manager
complete -W "create list remove apply reset stretched"                       24hg-custom-res
complete -W "analyze optimize report reset"                                  24hg-boot-speed

# Core tools
complete -W "getting-started commands gaming servers streaming hardware community updates troubleshooting about" 24hg-help
complete -W "status boost normal info"                                       24hg-performance
complete -W "start stop status config"                                       24hg-stream
complete -W "create restore list schedule"                                   24hg-backup
complete -W "start stop clip status save"                                    24hg-replay
complete -W "run compare history export"                                     24hg-benchmark
complete -W "full quick gpu network audio"                                   24hg-diag
complete -W "sync list restore delete status watch"                          24hg-cloud-saves
complete -W "start stop list status"                                         24hg-host
complete -W "show reset export import"                                       24hg-settings
complete -W "list apply preview reset"                                       24hg-themes
complete -W "set random slideshow list"                                      24hg-wallpaper
complete -W "take area window delay"                                         24hg-screenshot
complete -W "capture save list upload delete start stop share"              24hg-clip
complete -W "show hide toggle config start"                                  24hg-overlay
complete -W "run compare share history leaderboard"                          24hg-rig-score

# Wave 5 tools
complete -W "list apply create delete"                                       24hg-game-profiles
complete -W "scan configure test calibrate list"                             24hg-controller
complete -W "update check list rollback"                                     24hg-proton-updater
complete -W "stats today weekly reset"                                       24hg-game-timer

# Wave 8 troubleshooting tools
complete -W "check scan fix report"                                          24hg-compat
complete -W "scan fix report"                                                24hg-crash-fix
complete -W "status configure reset"                                         24hg-display
complete -W "start stop status"                                              24hg-discord-screen
complete -W "scan fix list create delete"                                    24hg-prefix
complete -W "detect setup grub status"                                       24hg-dualboot

# Wave 9 adoption tools
complete -W "scan import status"                                             24hg-migrate
complete -W "run compare export"                                             24hg-benchmark-compare
complete -W "list redeem status"                                             24hg-perks
complete -W "create export publish"                                          24hg-creator-kit
complete -W "start stop reset"                                               24hg-demo

# Wave 10 smart gaming tools
complete -W "list search info launch"                                        24hg-games
complete -W "status monitor alerts history"                                  24hg-thermal
complete -W "status queue pause resume cancel"                               24hg-download-mgr
complete -W "last today weekly"                                              24hg-session-summary

# Wave 11 gap-filler tools
complete -W "scan fix status"                                                24hg-anticheat-tracker
complete -W "status enable disable calibrate"                                24hg-hdr
complete -W "scan fix list"                                                  24hg-flatpak-fix
complete -W "status enable disable schedule"                                 24hg-update-guard
complete -W "list backup restore delete sync"                                24hg-save-manager
complete -W "fix status check"                                               24hg-nvidia-wayland

# Wave 12 game setup
complete -W "gtav hogwarts starfield forza warframe minecraft list"          24hg-game-setup

# Wave 13 killer features
complete -W "setup start stop status"                                        24hg-sunshine-setup
complete -W "scan announce status peers"                                     24hg-lan-party
complete -W "play stop next list stations"                                   24hg-radio
complete -W "create list join delete"                                        24hg-invite
complete -W "check report list"                                              24hg-game-compat
complete -W "list join create"                                               24hg-tournament
complete -W "start stop list set"                                            24hg-live-wallpaper
complete -W "tune scan report reset"                                         24hg-hw-optimizer

# Wave 14 social + intelligence tools
complete -W "list progress unlock"                                           24hg-achievements
complete -W "play list recent favorites"                                     24hg-launch
complete -W "test optimize report reset"                                     24hg-ping-optimizer
complete -W "scan fix report"                                                24hg-rescue
complete -W "list share upload delete"                                       24hg-gallery
complete -W "list install remove update search"                              24hg-mods

# Wave 15 infrastructure tools
complete -W "join leave peers status"                                        24hg-vpn
complete -W "list setup play scan import"                                    24hg-retro
complete -W "join leave ptt-bind status"                                     24hg-voice

# Wave 16 polish + security tools
complete -W "send list clear config"                                         24hg-notify
complete -W "start skip reset"                                               24hg-tour
complete -W "generate list read"                                             24hg-digest
complete -W "list read subscribe"                                            24hg-feed
complete -W "status enable disable rules"                                    24hg-firewall
complete -W "scan report upload"                                             24hg-crash-report
complete -W "list set speed test"                                            24hg-mirror

# Wave 17 smart gaming + family + hardware
complete -W "fix explain optimize"                                           24hg-ai
complete -W "live start stop report"                                         24hg-perflog
complete -W "check wishlist alerts"                                          24hg-deals
complete -W "scan recent highlights"                                         24hg-highlights
complete -W "status enable disable rules"                                    24hg-parental
complete -W "status colorblind magnify contrast"                             24hg-a11y
complete -W "status gaming battery balanced"                                 24hg-laptop
complete -W "list configure calibrate profiles"                              24hg-controllers
complete -W "list join create progress"                                      24hg-challenges
complete -W "start stop status"                                              24hg-discord-rpc
complete -W "create list restore delete"                                     24hg-snapshot
complete -W "scan import verify status"                                      24hg-windows-import

# Wave 18 server hosting + streaming + hardware
complete -W "start stop status setup"                                        24hg-go-live
complete -W "start stop status"                                              24hg-record
complete -W "status start stop setup"                                        24hg-vr
complete -W "list mount add eject"                                           24hg-gamedrive
complete -W "scan mount status"                                              24hg-nas
complete -W "check recommend list"                                           24hg-proton-pick
complete -W "list create restore schedule"                                   24hg-game-backup
complete -W "start stop status"                                              24hg-splitscreen
complete -W "on off status timer"                                            24hg-focus

# Simpler tools (no subcommands or single-purpose)
complete -W "status on off auto"                                             24hg-nightlight
complete -W "scan optimize clear status"                                     24hg-shader-cache
complete -W "daily random list"                                              24hg-tips
complete -W "play stop list volume"                                          24hg-sounds
complete -W "login logout status sync"                                       24hg-hub-bridge
complete -W "--once --watch --json"                                          24hg-server-status
complete -W "status scan report"                                             24hg-audio
complete -W "status check fix"                                               24hg-netguard
complete -W "scan fix list"                                                  24hg-proton-fix

# ---------------------------------------------------------------------------
# Master 24hg- prefix completion (typing "24hg-<TAB>" lists all commands)
# ---------------------------------------------------------------------------
_24hg_master_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    if [[ "$cur" == 24hg-* ]]; then
        COMPREPLY=($(compgen -W "${_24HG_ALL_COMMANDS}" -- "${cur}"))
    fi
}

# Bind to the empty command so "24hg-<TAB>" works at the prompt
# This hooks into bash's default command completion
complete -D -F _24hg_master_complete 2>/dev/null

# Also register a completion function that activates when the user types
# "24hg" and presses TAB (handles "24hg-" prefix via command_not_found)
_24hg_command_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    COMPREPLY=($(compgen -W "${_24HG_ALL_COMMANDS}" -- "${cur}"))
}

# If bash-completion is available, hook into its command-not-found handler
# so that "24hg-<TAB>" works even for commands not yet on PATH
if declare -F _command_offset &>/dev/null 2>&1; then
    complete -o default -F _24hg_command_complete 24hg-
fi
