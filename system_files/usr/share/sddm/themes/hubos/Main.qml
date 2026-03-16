import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0a0a14"

    // Background image
    Image {
        id: background
        anchors.fill: parent
        source: config.background || ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0.4
    }

    // Gradient overlay
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#cc0a0a14" }
            GradientStop { position: 0.5; color: "#880a0a14" }
            GradientStop { position: 1.0; color: "#cc0a0a14" }
        }
    }

    // Center login card
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: 420
        height: 480
        radius: 16
        color: "#dd0e0e1c"
        border.color: "#2058a6ff"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 20

            // Logo
            Image {
                source: "logo.png"
                Layout.preferredWidth: 80
                Layout.preferredHeight: 80
                Layout.alignment: Qt.AlignHCenter
                fillMode: Image.PreserveAspectFit
            }

            // Title
            Text {
                text: "HubOS"
                font.pixelSize: 28
                font.bold: true
                color: "#ffffff"
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: "24 Hour Gaming"
                font.pixelSize: 13
                color: "#8080b0"
                Layout.alignment: Qt.AlignHCenter
            }

            Item { Layout.fillHeight: true; Layout.maximumHeight: 10 }

            // Username
            TextField {
                id: userField
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                placeholderText: "Username"
                font.pixelSize: 14
                color: "#e0e0f0"
                placeholderTextColor: "#606080"
                background: Rectangle {
                    radius: 8
                    color: "#1a1a2e"
                    border.color: userField.activeFocus ? "#58a6ff" : "#2a2a3e"
                    border.width: 1
                }
                Keys.onReturnPressed: passwordField.forceActiveFocus()
                text: userModel.lastUser
            }

            // Password
            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                placeholderText: "Password"
                echoMode: TextInput.Password
                font.pixelSize: 14
                color: "#e0e0f0"
                placeholderTextColor: "#606080"
                background: Rectangle {
                    radius: 8
                    color: "#1a1a2e"
                    border.color: passwordField.activeFocus ? "#58a6ff" : "#2a2a3e"
                    border.width: 1
                }
                Keys.onReturnPressed: loginButton.clicked()
            }

            // Session selector
            ComboBox {
                id: sessionSelector
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.pixelSize: 13
                background: Rectangle {
                    radius: 8
                    color: "#1a1a2e"
                    border.color: "#2a2a3e"
                    border.width: 1
                }
                contentItem: Text {
                    text: sessionSelector.displayText
                    color: "#c0c0d0"
                    font.pixelSize: 13
                    verticalAlignment: Text.AlignVCenter
                    leftPadding: 12
                }
            }

            // Login button
            Button {
                id: loginButton
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                text: "Login"
                font.pixelSize: 15
                font.bold: true
                onClicked: sddm.login(userField.text, passwordField.text, sessionSelector.currentIndex)
                background: Rectangle {
                    radius: 8
                    color: loginButton.pressed ? "#3b82f6" : (loginButton.hovered ? "#4a94ff" : "#58a6ff")
                }
                contentItem: Text {
                    text: loginButton.text
                    color: "#ffffff"
                    font: loginButton.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Error message
            Text {
                id: errorMessage
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 12
                color: "#ff5555"
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
            }
        }
    }

    // Clock in top-right
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 30
        font.pixelSize: 42
        font.bold: true
        color: "#ffffff"
        opacity: 0.7
        text: Qt.formatTime(new Date(), "HH:mm")

        Timer {
            interval: 30000
            running: true
            repeat: true
            onTriggered: parent.text = Qt.formatTime(new Date(), "HH:mm")
        }
    }

    // Date below clock
    Text {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 80
        anchors.rightMargin: 30
        font.pixelSize: 16
        color: "#8080b0"
        text: Qt.formatDate(new Date(), "dddd, MMMM d")
    }

    // Power buttons bottom-right
    Row {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 30
        spacing: 15

        ImageButton {
            source: "icons/reboot.svg"
            width: 32; height: 32
            onClicked: sddm.reboot()
            visible: sddm.canReboot
        }
        ImageButton {
            source: "icons/shutdown.svg"
            width: 32; height: 32
            onClicked: sddm.powerOff()
            visible: sddm.canPowerOff
        }
    }

    // Bottom branding
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 20
        font.pixelSize: 11
        color: "#404060"
        text: "HubOS — 24hgaming.com"
    }

    // Handle login failure
    Connections {
        target: sddm
        function onLoginFailed() {
            errorMessage.text = "Invalid username or password"
            passwordField.text = ""
            passwordField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            errorMessage.text = ""
        }
    }

    Component.onCompleted: {
        if (userField.text !== "") {
            passwordField.forceActiveFocus()
        } else {
            userField.forceActiveFocus()
        }
    }
}
