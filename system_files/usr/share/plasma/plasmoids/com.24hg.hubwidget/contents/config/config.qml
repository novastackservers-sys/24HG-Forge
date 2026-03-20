import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami 2.20 as Kirigami

Kirigami.FormLayout {
    id: configPage

    property alias cfg_refreshInterval: refreshIntervalSpinBox.value
    property alias cfg_showFriends: showFriendsCheckBox.checked
    property alias cfg_showServers: showServersCheckBox.checked
    property alias cfg_showClips: showClipsCheckBox.checked
    property alias cfg_showEvents: showEventsCheckBox.checked
    property alias cfg_maxFriends: maxFriendsSpinBox.value

    QQC2.SpinBox {
        id: refreshIntervalSpinBox
        Kirigami.FormData.label: "Refresh interval (seconds):"
        from: 30
        to: 3600
        stepSize: 30
        value: 300
    }

    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Visible Sections" }

    QQC2.CheckBox {
        id: showFriendsCheckBox
        Kirigami.FormData.label: "Show Friends Online:"
        checked: true
    }

    QQC2.CheckBox {
        id: showServersCheckBox
        Kirigami.FormData.label: "Show Server Status:"
        checked: true
    }

    QQC2.CheckBox {
        id: showClipsCheckBox
        Kirigami.FormData.label: "Show Recent Clips:"
        checked: true
    }

    QQC2.CheckBox {
        id: showEventsCheckBox
        Kirigami.FormData.label: "Show Upcoming Events:"
        checked: true
    }

    Item { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Limits" }

    QQC2.SpinBox {
        id: maxFriendsSpinBox
        Kirigami.FormData.label: "Max friends shown:"
        from: 1
        to: 50
        stepSize: 1
        value: 10
    }
}
