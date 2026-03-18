/*
 * 24HG Forge Boot Splash — 24 Hour Gaming
 * KDE Plasma Look-and-Feel splash screen
 */

import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15

Rectangle {
    id: root
    color: "#0a0a14"
    anchors.fill: parent

    property int stage: 0

    onStageChanged: {
        if (stage === 1) {
            introAnimation.running = true;
            progressAnimation.running = true;
        }
    }

    // ---------- subtle background gradient vignette ----------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0a14" }
            GradientStop { position: 0.4; color: "#0d0d1a" }
            GradientStop { position: 1.0; color: "#060610" }
        }
    }

    // ---------- faint radial glow behind logo ----------
    Rectangle {
        id: glowBg
        width: 420
        height: 420
        radius: 210
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -30
        color: "transparent"
        border.width: 0

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0.83, 1, 0.06) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    // ---------- main content column ----------
    Item {
        id: content
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        width: parent.width
        height: logoText.height + taglineText.height + 24
        opacity: 0
        scale: 0.92

        // --- 24HG Forge title ---
        Text {
            id: logoText
            anchors.horizontalCenter: parent.horizontalCenter
            text: "24HG Forge"
            font.family: "Segoe UI, Noto Sans, sans-serif"
            font.pixelSize: 72
            font.weight: Font.Bold
            font.letterSpacing: 6
            color: "#ffffff"
            style: Text.Raised
            styleColor: Qt.rgba(0, 0.83, 1, 0.15)

            // pulsing opacity animation
            SequentialAnimation on opacity {
                id: pulseAnimation
                loops: Animation.Infinite
                running: true
                NumberAnimation { from: 1.0; to: 0.6; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.6; to: 1.0; duration: 1800; easing.type: Easing.InOutSine }
            }
        }

        // --- 24 Hour Gaming tagline ---
        Text {
            id: taglineText
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: logoText.bottom
            anchors.topMargin: 12
            text: "24 Hour Gaming"
            font.family: "Segoe UI, Noto Sans, sans-serif"
            font.pixelSize: 22
            font.weight: Font.DemiBold
            font.letterSpacing: 4
            color: "#00d4ff"
            opacity: 0.85
        }

        // --- thin accent line under tagline ---
        Rectangle {
            id: accentLine
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: taglineText.bottom
            anchors.topMargin: 16
            width: 120
            height: 1
            color: Qt.rgba(0, 0.83, 1, 0.3)
            radius: 1
        }
    }

    // ---------- intro fade / scale animation ----------
    ParallelAnimation {
        id: introAnimation
        running: false
        NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 900; easing.type: Easing.OutCubic }
        NumberAnimation { target: content; property: "scale"; from: 0.92; to: 1.0; duration: 900; easing.type: Easing.OutCubic }
    }

    // ---------- loading bar ----------
    Item {
        id: progressContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.round(parent.height * 0.10)
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(340, parent.width * 0.28)
        height: 3

        // track
        Rectangle {
            id: progressTrack
            anchors.fill: parent
            radius: 2
            color: "#1a1a2e"
        }

        // fill
        Rectangle {
            id: progressFill
            height: parent.height
            radius: 2
            width: 0
            color: "#00d4ff"

            // soft glow
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 0

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 6
                    height: parent.height + 4
                    radius: parent.radius + 2
                    color: Qt.rgba(0, 0.83, 1, 0.15)
                    z: -1
                }
            }
        }
    }

    // ---------- progress bar animation ----------
    SequentialAnimation {
        id: progressAnimation
        running: false

        // initial fast burst
        NumberAnimation {
            target: progressFill
            property: "width"
            from: 0
            to: progressContainer.width * 0.35
            duration: 600
            easing.type: Easing.OutQuad
        }
        // slow middle phase
        NumberAnimation {
            target: progressFill
            property: "width"
            to: progressContainer.width * 0.70
            duration: 2400
            easing.type: Easing.InOutSine
        }
        // quick finish
        NumberAnimation {
            target: progressFill
            property: "width"
            to: progressContainer.width
            duration: 400
            easing.type: Easing.InCubic
        }
    }

    // ---------- version watermark ----------
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 16
        text: "v1.0"
        font.pixelSize: 10
        color: Qt.rgba(1, 1, 1, 0.15)
    }
}
