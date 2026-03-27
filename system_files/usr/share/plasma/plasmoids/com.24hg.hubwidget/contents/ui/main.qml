import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import Qt.labs.platform 1.1 as Platform

PlasmoidItem {
    id: root

    readonly property string apiBase: "https://hub.24hgaming.com/api"
    readonly property color accentColor: "#00d4ff"
    readonly property color bgColor: "#040910"
    readonly property color bgSecondary: "#12122a"
    readonly property color bgTertiary: "#1a1a3e"
    readonly property color textColor: "#a0a0c0"
    readonly property color textBright: "#e0e0f0"
    readonly property color greenDot: "#00e676"
    readonly property color yellowDot: "#ffd740"
    readonly property color grayDot: "#606080"

    property string authToken: ""
    property bool authenticated: false
    property bool loading: false
    property string errorMessage: ""

    property var friendsData: []
    property var serversData: []
    property var clipsData: []
    property var eventsData: []
    property var feedData: []
    property int onlineFriendCount: 0
    property int currentTab: 0  // 0 = Dashboard, 1 = Feed

    switchWidth: Kirigami.Units.gridUnit * 12
    switchHeight: Kirigami.Units.gridUnit * 16

    Plasmoid.configurationRequired: false

    // ── Token loading ──
    function loadToken() {
        var tokenPath = Platform.StandardPaths.writableLocation(Platform.StandardPaths.ConfigLocation) + "/24hg/hub-token";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", "file://" + tokenPath, false);
        try {
            xhr.send();
            if (xhr.status === 200 || xhr.status === 0) {
                authToken = xhr.responseText.trim();
                authenticated = authToken.length > 0;
            } else {
                authenticated = false;
            }
        } catch (e) {
            authenticated = false;
        }
    }

    // ── API fetch helper ──
    function apiFetch(endpoint, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiBase + endpoint);
        xhr.setRequestHeader("Authorization", "Bearer " + authToken);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        callback(null, data);
                    } catch (e) {
                        callback("Failed to parse response", null);
                    }
                } else if (xhr.status === 401 || xhr.status === 403) {
                    authenticated = false;
                    callback("Not authenticated", null);
                } else {
                    callback("HTTP " + xhr.status, null);
                }
            }
        };
        xhr.send();
    }

    // ── Refresh all data ──
    function refreshAll() {
        if (!authenticated) return;

        loading = true;
        errorMessage = "";
        var pending = 0;
        var totalSections = 0;

        function sectionDone() {
            pending--;
            if (pending <= 0) loading = false;
        }

        if (Plasmoid.configuration.showFriends) {
            totalSections++;
            pending++;
            apiFetch("/friends/online", function(err, data) {
                if (!err && data) {
                    var maxF = Plasmoid.configuration.maxFriends || 10;
                    var list = Array.isArray(data) ? data : (data.friends || []);
                    friendsData = list.slice(0, maxF);
                    onlineFriendCount = list.length;
                } else if (err && err !== "Not authenticated") {
                    friendsData = [];
                    onlineFriendCount = 0;
                }
                sectionDone();
            });
        }

        if (Plasmoid.configuration.showServers) {
            totalSections++;
            pending++;
            apiFetch("/servers/status", function(err, data) {
                if (!err && data) {
                    serversData = Array.isArray(data) ? data : (data.servers || []);
                } else if (err && err !== "Not authenticated") {
                    serversData = [];
                }
                sectionDone();
            });
        }

        if (Plasmoid.configuration.showClips) {
            totalSections++;
            pending++;
            apiFetch("/clips/recent", function(err, data) {
                if (!err && data) {
                    var list = Array.isArray(data) ? data : (data.clips || []);
                    clipsData = list.slice(0, 3);
                } else if (err && err !== "Not authenticated") {
                    clipsData = [];
                }
                sectionDone();
            });
        }

        if (Plasmoid.configuration.showEvents) {
            totalSections++;
            pending++;
            apiFetch("/tournaments/upcoming", function(err, data) {
                if (!err && data) {
                    var list = Array.isArray(data) ? data : (data.tournaments || data.events || []);
                    eventsData = list.slice(0, 2);
                } else if (err && err !== "Not authenticated") {
                    eventsData = [];
                }
                sectionDone();
            });
        }

        // Always fetch feed data
        totalSections++;
        pending++;
        apiFetch("/24hg/feed?limit=20", function(err, data) {
            if (!err && data) {
                var list = Array.isArray(data) ? data : (data.feed || data.activities || []);
                feedData = list.slice(0, 20);
            } else if (err && err !== "Not authenticated") {
                feedData = [];
            }
            sectionDone();
        });

        if (totalSections === 0) loading = false;
    }

    // ── Time ago helper ──
    function timeAgo(dateStr) {
        if (!dateStr) return "";
        var then = new Date(dateStr);
        var now = new Date();
        var diff = Math.floor((now - then) / 1000);
        if (diff < 60) return diff + "s ago";
        if (diff < 3600) return Math.floor(diff / 60) + "m ago";
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
        return Math.floor(diff / 86400) + "d ago";
    }

    // ── Server fullness color ──
    function fullnessColor(players, maxPlayers) {
        if (maxPlayers <= 0) return grayDot;
        var ratio = players / maxPlayers;
        if (ratio >= 0.8) return "#ff5252";
        if (ratio >= 0.5) return yellowDot;
        if (ratio > 0) return greenDot;
        return grayDot;
    }

    // ── Status dot color ──
    function statusDotColor(status) {
        if (status === "in-game" || status === "ingame" || status === "playing") return yellowDot;
        if (status === "online") return greenDot;
        return grayDot;
    }

    // ── Activity feed helpers ──
    function activityLabel(atype) {
        var labels = {
            "playing": "[PLAYING]",
            "achievement": "[ACHIEVEMENT]",
            "clip": "[CLIP]",
            "screenshot": "[SCREENSHOT]",
            "rank": "[RANK]",
            "tournament": "[TOURNAMENT]",
            "voice": "[VOICE]"
        };
        return labels[atype] || "[ACTIVITY]";
    }

    function activityColor(atype) {
        var colors = {
            "playing": "#2196f3",
            "achievement": "#ffc107",
            "clip": "#ff9800",
            "screenshot": "#9c7cdb",
            "rank": "#4caf50",
            "tournament": "#f44336",
            "voice": "#00bcd4"
        };
        return colors[atype] || "#606080";
    }

    function activityDescription(item) {
        var user = item.username || item.user || "Unknown";
        var game = item.game || "";
        var detail = item.detail || item.details || "";
        var atype = item.type || "playing";

        switch (atype) {
            case "playing":
                return user + " is playing " + (game || "a game");
            case "achievement":
                var msg = user + " unlocked " + (detail || "an achievement");
                if (game) msg += " in " + game;
                return msg;
            case "clip":
                var msg = user + " shared a clip";
                if (item.title) msg += ": " + item.title;
                if (game) msg += " in " + game;
                return msg;
            case "screenshot":
                var msg = user + " shared a screenshot";
                if (game) msg += " in " + game;
                return msg;
            case "rank":
                var pos = item.position || item.rank || "?";
                var msg = user + " reached #" + pos + " on leaderboard";
                if (game) msg += " in " + game;
                return msg;
            case "tournament":
                var tn = item.tournament || detail || "a tournament";
                return user + " joined " + tn;
            case "voice":
                var room = item.room || item.channel || detail || "Unknown";
                return user + " is in voice: " + room;
            default:
                return user + " " + detail;
        }
    }

    Component.onCompleted: {
        loadToken();
        if (authenticated) refreshAll();
    }

    // ── Auto-refresh timer ──
    Timer {
        id: refreshTimer
        interval: (Plasmoid.configuration.refreshInterval || 300) * 1000
        running: authenticated
        repeat: true
        onTriggered: refreshAll()
    }

    // ── Compact representation (panel) ──
    compactRepresentation: MouseArea {
        id: compactRoot

        Layout.minimumWidth: compactRow.implicitWidth + Kirigami.Units.smallSpacing * 2
        Layout.minimumHeight: Kirigami.Units.iconSizes.small

        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactRow
            anchors.centerIn: parent
            spacing: Kirigami.Units.smallSpacing

            Rectangle {
                width: 8; height: 8; radius: 4
                color: root.authenticated ? root.greenDot : root.grayDot
            }

            PlasmaComponents.Label {
                text: root.authenticated ? root.onlineFriendCount + " | 24HG" : "24HG"
                color: root.accentColor
                font.bold: true
                font.pixelSize: Kirigami.Units.iconSizes.small
            }
        }
    }

    // ── Full representation (popup / desktop) ──
    fullRepresentation: Rectangle {
        id: fullRoot
        color: root.bgColor
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.preferredHeight: Kirigami.Units.gridUnit * 30
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 14

        // ── Not authenticated state ──
        ColumnLayout {
            anchors.centerIn: parent
            spacing: Kirigami.Units.largeSpacing
            visible: !root.authenticated

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: "24HG Hub"
                color: root.accentColor
                font.pixelSize: 24
                font.bold: true
            }

            PlasmaComponents.Label {
                Layout.alignment: Qt.AlignHCenter
                text: "Sign in to 24HG Hub to connect"
                color: root.textColor
                font.pixelSize: 13
            }

            PlasmaComponents.Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Connect to Hub"
                icon.name: "network-connect"
                onClicked: Qt.openUrlExternally("https://hub.24hgaming.com/settings/integrations")
            }

            PlasmaComponents.Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Retry"
                icon.name: "view-refresh"
                onClicked: {
                    root.loadToken();
                    if (root.authenticated) root.refreshAll();
                }
            }
        }

        // ── Authenticated: main dashboard ──
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: 0
            visible: root.authenticated

            // ── Header ──
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Kirigami.Units.smallSpacing

                PlasmaComponents.Label {
                    text: "24HG Hub"
                    color: root.accentColor
                    font.pixelSize: 18
                    font.bold: true
                    Layout.fillWidth: true
                }

                PlasmaComponents.ToolButton {
                    icon.name: "view-refresh"
                    enabled: !root.loading
                    onClicked: root.refreshAll()
                    PlasmaComponents.ToolTip { text: "Refresh" }
                }
            }

            // ── Tab bar ──
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: 2

                Repeater {
                    model: ["Dashboard", "Feed"]

                    Rectangle {
                        Layout.fillWidth: true
                        height: tabLabel.implicitHeight + Kirigami.Units.smallSpacing * 2
                        radius: 4
                        color: root.currentTab === index ? root.bgTertiary : "transparent"

                        PlasmaComponents.Label {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: root.currentTab === index ? root.accentColor : root.textColor
                            font.pixelSize: 12
                            font.bold: root.currentTab === index
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }
            }

            // ── Separator ──
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.bgTertiary
            }

            // ── Loading spinner ──
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 4
                visible: root.loading && root.friendsData.length === 0 && root.serversData.length === 0

                QQC2.BusyIndicator {
                    anchors.centerIn: parent
                    running: root.loading
                    palette.dark: root.accentColor
                }
            }

            // ══════════════════════════════════════════════
            // ── Feed Tab ──
            // ══════════════════════════════════════════════
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentTab === 1 && (!root.loading || root.feedData.length > 0)
                clip: true

                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                ColumnLayout {
                    width: fullRoot.width - Kirigami.Units.smallSpacing * 2
                    spacing: Kirigami.Units.smallSpacing

                    // Feed header
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing

                        PlasmaComponents.Label {
                            text: "Activity Feed"
                            color: root.accentColor
                            font.pixelSize: 13
                            font.bold: true
                            Layout.fillWidth: true
                        }

                        PlasmaComponents.Label {
                            text: root.feedData.length.toString()
                            color: root.textColor
                            font.pixelSize: 11
                        }
                    }

                    // Empty state
                    PlasmaComponents.Label {
                        visible: root.feedData.length === 0
                        text: "No recent activity from friends"
                        color: root.grayDot
                        font.pixelSize: 12
                        font.italic: true
                        Layout.leftMargin: Kirigami.Units.smallSpacing
                    }

                    // Feed entries
                    Repeater {
                        model: root.feedData

                        Rectangle {
                            Layout.fillWidth: true
                            height: feedEntryCol.implicitHeight + Kirigami.Units.smallSpacing * 2
                            color: feedEntryMouse.containsMouse ? root.bgTertiary : root.bgSecondary
                            radius: 4

                            MouseArea {
                                id: feedEntryMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    var url = modelData.url || modelData.profile_url || "";
                                    if (url) Qt.openUrlExternally(url);
                                }
                            }

                            ColumnLayout {
                                id: feedEntryCol
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: 2

                                // Activity label + username
                                RowLayout {
                                    spacing: Kirigami.Units.smallSpacing

                                    Rectangle {
                                        width: labelText.implicitWidth + 8
                                        height: labelText.implicitHeight + 4
                                        radius: 3
                                        color: root.activityColor(modelData.type || "playing")
                                        opacity: 0.85

                                        PlasmaComponents.Label {
                                            id: labelText
                                            anchors.centerIn: parent
                                            text: root.activityLabel(modelData.type || "playing")
                                            color: "#ffffff"
                                            font.pixelSize: 9
                                            font.bold: true
                                        }
                                    }

                                    PlasmaComponents.Label {
                                        text: modelData.username || modelData.user || "Unknown"
                                        color: root.textBright
                                        font.pixelSize: 12
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                // Activity description
                                PlasmaComponents.Label {
                                    text: root.activityDescription(modelData)
                                    color: root.textColor
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                }

                                // Timestamp
                                PlasmaComponents.Label {
                                    text: root.timeAgo(modelData.timestamp || modelData.created_at || modelData.date || "")
                                    color: root.grayDot
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }

                    // Bottom spacer
                    Item { Layout.fillHeight: true }
                }
            }

            // ══════════════════════════════════════════════
            // ── Dashboard Tab (original content) ──
            // ══════════════════════════════════════════════
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.currentTab === 0 && (!root.loading || root.friendsData.length > 0 || root.serversData.length > 0)
                clip: true

                QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

                ColumnLayout {
                    width: fullRoot.width - Kirigami.Units.smallSpacing * 2
                    spacing: Kirigami.Units.smallSpacing

                    // ══════════════════════════════════════
                    // ── Friends Online ──
                    // ══════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Plasmoid.configuration.showFriends
                        spacing: 2

                        // Section header
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: Kirigami.Units.smallSpacing

                            PlasmaComponents.Label {
                                text: "Friends Online"
                                color: root.accentColor
                                font.pixelSize: 13
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            PlasmaComponents.Label {
                                text: root.onlineFriendCount.toString()
                                color: root.textColor
                                font.pixelSize: 11
                            }
                        }

                        // Empty state
                        PlasmaComponents.Label {
                            visible: root.friendsData.length === 0
                            text: "No friends online"
                            color: root.grayDot
                            font.pixelSize: 12
                            font.italic: true
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                        }

                        // Friends list
                        Repeater {
                            model: root.friendsData

                            Rectangle {
                                Layout.fillWidth: true
                                height: friendRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                                color: friendMouse.containsMouse ? root.bgTertiary : root.bgSecondary
                                radius: 4

                                MouseArea {
                                    id: friendMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var profileUrl = modelData.profile_url || ("https://hub.24hgaming.com/u/" + (modelData.username || ""));
                                        Qt.openUrlExternally(profileUrl);
                                    }
                                }

                                RowLayout {
                                    id: friendRow
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: root.statusDotColor(modelData.status || "online")
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        PlasmaComponents.Label {
                                            text: modelData.username || modelData.name || "Unknown"
                                            color: root.textBright
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        PlasmaComponents.Label {
                                            text: modelData.game || modelData.activity || modelData.status || ""
                                            color: root.textColor
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ══════════════════════════════════════
                    // ── Server Status ──
                    // ══════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Plasmoid.configuration.showServers
                        spacing: 2

                        PlasmaComponents.Label {
                            text: "Server Status"
                            color: root.accentColor
                            font.pixelSize: 13
                            font.bold: true
                            Layout.topMargin: Kirigami.Units.smallSpacing
                        }

                        PlasmaComponents.Label {
                            visible: root.serversData.length === 0
                            text: "No server data"
                            color: root.grayDot
                            font.pixelSize: 12
                            font.italic: true
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                        }

                        Repeater {
                            model: root.serversData

                            Rectangle {
                                Layout.fillWidth: true
                                height: serverRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                                color: serverMouse.containsMouse ? root.bgTertiary : root.bgSecondary
                                radius: 4

                                MouseArea {
                                    id: serverMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var connectUrl = modelData.connect_url || ("https://hub.24hgaming.com/servers/" + (modelData.id || ""));
                                        Qt.openUrlExternally(connectUrl);
                                    }
                                }

                                RowLayout {
                                    id: serverRow
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        PlasmaComponents.Label {
                                            text: modelData.name || "Server"
                                            color: root.textBright
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        PlasmaComponents.Label {
                                            text: modelData.game || ""
                                            color: root.textColor
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                        }
                                    }

                                    // Player count badge
                                    Rectangle {
                                        width: playerCountLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                                        height: playerCountLabel.implicitHeight + 4
                                        radius: 3
                                        color: root.fullnessColor(modelData.players || 0, modelData.max_players || 1)
                                        opacity: 0.85

                                        PlasmaComponents.Label {
                                            id: playerCountLabel
                                            anchors.centerIn: parent
                                            text: (modelData.players || 0) + "/" + (modelData.max_players || "?")
                                            color: "#ffffff"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ══════════════════════════════════════
                    // ── Recent Clips ──
                    // ══════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Plasmoid.configuration.showClips
                        spacing: 2

                        PlasmaComponents.Label {
                            text: "Recent Clips"
                            color: root.accentColor
                            font.pixelSize: 13
                            font.bold: true
                            Layout.topMargin: Kirigami.Units.smallSpacing
                        }

                        PlasmaComponents.Label {
                            visible: root.clipsData.length === 0
                            text: "No recent clips"
                            color: root.grayDot
                            font.pixelSize: 12
                            font.italic: true
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                        }

                        Repeater {
                            model: root.clipsData

                            Rectangle {
                                Layout.fillWidth: true
                                height: clipRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                                color: clipMouse.containsMouse ? root.bgTertiary : root.bgSecondary
                                radius: 4

                                MouseArea {
                                    id: clipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var clipUrl = modelData.url || ("https://hub.24hgaming.com/clips/" + (modelData.id || ""));
                                        Qt.openUrlExternally(clipUrl);
                                    }
                                }

                                RowLayout {
                                    id: clipRow
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    // Thumbnail placeholder
                                    Rectangle {
                                        width: 48; height: 32
                                        radius: 3
                                        color: root.bgTertiary
                                        border.color: root.accentColor
                                        border.width: 1

                                        PlasmaComponents.Label {
                                            anchors.centerIn: parent
                                            text: "\u25B6"
                                            color: root.accentColor
                                            font.pixelSize: 14
                                        }

                                        // Thumbnail image (loads if available)
                                        Image {
                                            anchors.fill: parent
                                            source: modelData.thumbnail || ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: status === Image.Ready
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        PlasmaComponents.Label {
                                            text: modelData.title || "Untitled Clip"
                                            color: root.textBright
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        RowLayout {
                                            spacing: Kirigami.Units.smallSpacing

                                            PlasmaComponents.Label {
                                                text: modelData.author || modelData.username || ""
                                                color: root.textColor
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                visible: text.length > 0
                                            }

                                            PlasmaComponents.Label {
                                                text: root.timeAgo(modelData.created_at || modelData.date || "")
                                                color: root.grayDot
                                                font.pixelSize: 10
                                                visible: text.length > 0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ══════════════════════════════════════
                    // ── Upcoming Events ──
                    // ══════════════════════════════════════
                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: Plasmoid.configuration.showEvents
                        spacing: 2

                        PlasmaComponents.Label {
                            text: "Upcoming Events"
                            color: root.accentColor
                            font.pixelSize: 13
                            font.bold: true
                            Layout.topMargin: Kirigami.Units.smallSpacing
                        }

                        PlasmaComponents.Label {
                            visible: root.eventsData.length === 0
                            text: "No upcoming events"
                            color: root.grayDot
                            font.pixelSize: 12
                            font.italic: true
                            Layout.leftMargin: Kirigami.Units.smallSpacing
                        }

                        Repeater {
                            model: root.eventsData

                            Rectangle {
                                Layout.fillWidth: true
                                height: eventRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                                color: eventMouse.containsMouse ? root.bgTertiary : root.bgSecondary
                                radius: 4

                                MouseArea {
                                    id: eventMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var eventUrl = modelData.url || ("https://hub.24hgaming.com/events/" + (modelData.id || ""));
                                        Qt.openUrlExternally(eventUrl);
                                    }
                                }

                                RowLayout {
                                    id: eventRow
                                    anchors.fill: parent
                                    anchors.margins: Kirigami.Units.smallSpacing
                                    spacing: Kirigami.Units.smallSpacing

                                    // Calendar icon placeholder
                                    Rectangle {
                                        width: 36; height: 36
                                        radius: 4
                                        color: root.bgTertiary
                                        border.color: root.accentColor
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 0

                                            PlasmaComponents.Label {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: {
                                                    var d = modelData.date || modelData.start_date || "";
                                                    if (!d) return "--";
                                                    var dt = new Date(d);
                                                    return ["JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC"][dt.getMonth()] || "--";
                                                }
                                                color: root.accentColor
                                                font.pixelSize: 8
                                                font.bold: true
                                            }

                                            PlasmaComponents.Label {
                                                Layout.alignment: Qt.AlignHCenter
                                                text: {
                                                    var d = modelData.date || modelData.start_date || "";
                                                    if (!d) return "--";
                                                    return new Date(d).getDate().toString();
                                                }
                                                color: root.textBright
                                                font.pixelSize: 14
                                                font.bold: true
                                            }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        PlasmaComponents.Label {
                                            text: modelData.name || modelData.title || "Event"
                                            color: root.textBright
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        PlasmaComponents.Label {
                                            text: modelData.game || ""
                                            color: root.textColor
                                            font.pixelSize: 10
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                            visible: text.length > 0
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom spacer
                    Item { Layout.fillHeight: true }

                    // ── Footer ──
                    Rectangle {
                        Layout.fillWidth: true
                        height: footerRow.implicitHeight + Kirigami.Units.smallSpacing * 2
                        color: root.bgSecondary
                        radius: 4

                        RowLayout {
                            id: footerRow
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.smallSpacing

                            PlasmaComponents.Label {
                                text: "24hgaming.com"
                                color: root.textColor
                                font.pixelSize: 10
                                Layout.fillWidth: true

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://24hgaming.com")
                                }
                            }

                            PlasmaComponents.Label {
                                text: "Discord"
                                color: root.accentColor
                                font.pixelSize: 10
                                font.underline: true

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.openUrlExternally("https://discord.gg/ymfEjH6EJN")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
