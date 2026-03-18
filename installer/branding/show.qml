/* 24HG Forge Calamares Installer Slideshow */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Presentation {
    id: presentation

    Timer {
        interval: 8000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a14"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 30

                Text {
                    text: "Welcome to 24HG Forge"
                    font.pointSize: 28
                    font.bold: true
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "24 Hour Gaming's custom Linux distribution.\nBuilt for gamers, by gamers."
                    font.pointSize: 14
                    color: "#a0a0c0"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a14"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "88+ Game Servers"
                    font.pointSize: 24
                    font.bold: true
                    color: "#58a6ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "CS 1.6 • CS2 • TF2 • Rust • FiveM • Quake\nand many more — all accessible from the Hub"
                    font.pointSize: 13
                    color: "#a0a0c0"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a14"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Built-In Community"
                    font.pointSize: 24
                    font.bold: true
                    color: "#58a6ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Chat • Forums • Tournaments • Leaderboards\nVoice chat • Economy • Clans\n\nAll integrated. No extra apps needed."
                    font.pointSize: 13
                    color: "#a0a0c0"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a14"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Gaming Just Works"
                    font.pointSize: 24
                    font.bold: true
                    color: "#58a6ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "NVIDIA & AMD drivers pre-configured\nSteam, Lutris, Heroic auto-installed\nProton & Wine ready to go\nMangoHud performance overlay (F12)"
                    font.pointSize: 13
                    color: "#a0a0c0"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a14"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Two Modes"
                    font.pointSize: 24
                    font.bold: true
                    color: "#58a6ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "24HG Mode — Console-like experience\nBoots straight into the Hub with Gamescope\n\nDesktop Mode — Full KDE Plasma desktop\nWith 24HG Hub pinned and ready"
                    font.pointSize: 13
                    color: "#a0a0c0"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0a0a14"

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    text: "Safe & Automatic Updates"
                    font.pointSize: 24
                    font.bold: true
                    color: "#58a6ff"
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "Immutable OS — system files are read-only\nAtomic updates that never break your system\nRollback to previous version if anything goes wrong\n\nPowered by Fedora Atomic + Bazzite"
                    font.pointSize: 13
                    color: "#a0a0c0"
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
