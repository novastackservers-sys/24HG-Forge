/* 24HG Calamares Installer Slideshow */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Presentation {
    id: presentation

    Timer {
        interval: 7000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    // ── Slide 1: Welcome ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Image {
                    source: "logo.png"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: "Welcome to 24HG"
                    font.pointSize: 32
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "The Gaming Linux Distro by 24 Hour Gaming"
                    font.pointSize: 16
                    color: "#8899aa"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "150+ built-in tools  •  89 game servers  •  One community"
                    font.pointSize: 12
                    color: "#556677"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // ── Slide 2: Game Ready ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "⚡ Game Ready"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Install a game → 24HG auto-optimizes it\n\n✓  Optimal Proton version selected\n✓  Launch arguments configured\n✓  Shader cache pre-built\n✓  Performance profile applied\n✓  Controller mappings set\n\nYou just click Play."
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 3: 89 Servers ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "🎮 89 Game Servers"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "CS2  •  CS 1.6  •  TF2  •  CSS  •  Rust  •  FiveM\nQuake  •  DoD:S  •  L4D  •  Insurgency  •  NMRiH\n\nConnect from the Hub or type:\n\n    connect-rust\n    connect-cs2\n    connect-tf2"
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 4: Smart OS ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "🧠 Smart Gaming OS"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Updates wait until you're done gaming\nPer-game performance profiles apply automatically\nHardware Scout monitors your system health\nQuick Resume saves your session across reboots\nSmart power management for laptops\n\n24HG thinks so you don't have to."
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 5: Hardware Control ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "🔧 No Extra Software Needed"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Mouse DPI & RGB lighting → built in\nPer-app audio routing → built in\nInput lag optimization → built in\nDual GPU switching → built in\nMod manager → built in\nCustom resolutions → built in\n\n24HG replaces Razer Synapse, Voicemeeter,\nMSI Afterburner, and Vortex."
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 6: Community ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "👥 Built-In Community"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Your desktop and hub.24hgaming.com share everything:\n\nClips & Screenshots → upload from desktop, view on web\nAchievements & Challenges → earn on desktop, show on profile\nCloud Saves → sync between machines\nRig Leaderboard → how does your hardware rank?\nWeekly Digest → your personal gaming stats\n\nOne account. One community. Everywhere."
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 7: Stream & Record ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "📺 Stream, Clip, Share"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Stream your PC to any device → sunshine\nCapture last 30 seconds → clip\nTake a screenshot → screenshot\nGo live on Twitch/YouTube → go-live\nHost a game server → host-game minecraft\n\nAll one command. All built in."
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 8: Two Modes ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "🖥️ Desktop Mode  ⟷  🎮 Game Mode"
                    font.pointSize: 24
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Desktop Mode\nFull KDE Plasma desktop with all 150+ 24HG tools\n\nGame Mode\nGamescope + Steam Big Picture — console experience\n\nSwitch anytime: 24hg-boot-select toggle"
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 9: Safe Updates ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "🔒 Unbreakable"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Immutable OS — system files are read-only\nAtomic updates — all or nothing, never half-broken\nAuto-snapshot before every update\nOne-command rollback if anything goes wrong\nSandboxed gaming — games can't touch your files\n\nPowered by Fedora Atomic + Bazzite"
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 10: LAN Party ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "🎉 LAN Party Mode"
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "One command: lan-mode\n\nAuto-discover other 24HG gamers on your network\nShare files and maps instantly\nVote on which game to play\nBuilt-in chat between party members\nCommunity radio for background beats\n\nBring your friends. We handle the rest."
                    font.pointSize: 13
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }

    // ── Slide 11: Ready ──
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#040910"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 24

                Image {
                    source: "logo.png"
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: "Almost there..."
                    font.pointSize: 28
                    font.bold: true
                    color: "#00e5ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "After install, type  help  in the terminal\nto see everything 24HG can do.\n\nJoin us at hub.24hgaming.com\nDiscord: discord.gg/ymfEjH6EJN\n\nWelcome to the 24HG family. 🎮"
                    font.pointSize: 14
                    color: "#8899aa"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    lineHeight: 1.3
                }
            }
        }
    }
}
