import QtQuick
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#0a0a14"

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorLabel.text = textConstants.loginFailed
            password.text = ""
            password.focus = true
        }
        function onLoginSucceeded() {
            errorLabel.text = ""
        }
    }

    // Background image
    Image {
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

    // Clock top-right
    Clock {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 30
        color: "#ffffff"
        timeFont.pixelSize: 42
        timeFont.bold: true
        dateFont.pixelSize: 16
        dateColor: "#8080b0"
    }

    // Center login card
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        width: 420
        height: 460
        radius: 16
        color: "#dd0e0e1c"
        border.color: "#2058a6ff"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 18

            // Logo
            Image {
                source: "logo.png"
                width: 80
                height: 80
                anchors.horizontalCenter: parent.horizontalCenter
                fillMode: Image.PreserveAspectFit
            }

            // Title
            Text {
                text: "HubOS"
                font.pixelSize: 28
                font.bold: true
                color: "#ffffff"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "24 Hour Gaming"
                font.pixelSize: 13
                color: "#8080b0"
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Spacer
            Item { width: 1; height: 5 }

            // Username
            TextBox {
                id: username
                width: parent.width
                height: 44
                font.pixelSize: 14
                color: "#1a1a2e"
                borderColor: focus ? "#58a6ff" : "#2a2a3e"
                textColor: "#e0e0f0"
                text: userModel.lastUser
                KeyNavigation.tab: password
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        password.focus = true
                        event.accepted = true
                    }
                }
            }

            // Password
            PasswordBox {
                id: password
                width: parent.width
                height: 44
                font.pixelSize: 14
                color: "#1a1a2e"
                borderColor: focus ? "#58a6ff" : "#2a2a3e"
                textColor: "#e0e0f0"
                tooltipBG: "#1a1a2e"
                KeyNavigation.tab: loginButton
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(username.text, password.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            // Session selector
            ComboBox {
                id: session
                width: parent.width
                height: 36
                font.pixelSize: 13
                color: "#1a1a2e"
                borderColor: "#2a2a3e"
                textColor: "#c0c0d0"
                arrowColor: "#606080"
                model: sessionModel
                index: sessionModel.lastIndex
                KeyNavigation.tab: username
            }

            // Login button
            Rectangle {
                id: loginButton
                width: parent.width
                height: 48
                radius: 8
                color: loginArea.pressed ? "#3b82f6" : (loginArea.containsMouse ? "#4a94ff" : "#58a6ff")

                Text {
                    anchors.centerIn: parent
                    text: "Login"
                    color: "#ffffff"
                    font.pixelSize: 15
                    font.bold: true
                }

                MouseArea {
                    id: loginArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.login(username.text, password.text, sessionIndex)
                }

                focus: true
                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        sddm.login(username.text, password.text, sessionIndex)
                        event.accepted = true
                    }
                }
            }

            // Error message
            Text {
                id: errorLabel
                width: parent.width
                font.pixelSize: 12
                color: "#ff5555"
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                text: ""
            }
        }
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

    Component.onCompleted: {
        if (username.text !== "") {
            password.focus = true
        } else {
            username.focus = true
        }
    }
}
