import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? PlasmaCore.Types.NoBackground
        : PlasmaCore.Types.DefaultBackground

    property var usage: ({
        status: "loading",
        planType: "",
        primary: null,
        secondary: null
    })
    property bool refreshing: false
    property string lastError: ""
    property string helperPath: decodeURIComponent(
        Qt.resolvedUrl("../code/fetch_limits.py").toString().replace("file://", ""))
    readonly property int refreshIntervalMs: Math.max(
        1, Number(Plasmoid.configuration.refreshIntervalSeconds)) * 1000

    // Desktop widgets always retain the dial, even at very small sizes.
    // Panel applets keep normal compact/full switching thresholds.
    switchWidth: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? 0 : Kirigami.Units.gridUnit * 12
    switchHeight: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? 0 : Kirigami.Units.gridUnit * 8
    preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar
        ? fullRepresentation : compactRepresentation

    function refresh() {
        refreshing = true
        lastError = ""
        limitsSource.disconnectSource(limitsSource.command)
        limitsSource.connectSource(limitsSource.command)
    }

    function resetAtLabel(window) {
        if (!window || !window.resetsAt) return i18n("Unavailable")
        const reset = new Date(Number(window.resetsAt) * 1000)
        return Qt.formatDateTime(reset, "ddd, MMM d, yyyy h:mm AP")
    }

    function resetsInLabel(window) {
        if (!window || !window.resetsAt) return i18n("Unavailable")
        const reset = new Date(Number(window.resetsAt) * 1000)
        const now = new Date()
        const diffMinutes = Math.max(0, Math.ceil((reset.getTime() - now.getTime()) / 60000))
        if (diffMinutes < 60) return i18np("%1 minute", "%1 minutes", diffMinutes)
        if (diffMinutes < 1440) {
            const hours = Math.ceil(diffMinutes / 60)
            return i18np("%1 hour", "%1 hours", hours)
        }
        const days = Math.ceil(diffMinutes / 1440)
        return i18np("%1 day", "%1 days", days)
    }

    function updatedAtLabel() {
        if (!root.usage.fetchedAt) return i18n("Unavailable")
        return Qt.formatDateTime(new Date(root.usage.fetchedAt * 1000),
            "ddd, MMM d, yyyy h:mm:ss AP")
    }

    function planLabel(plan) {
        if (!plan || plan === "unknown") return i18n("Codex")
        return "Codex " + plan.charAt(0).toUpperCase()
            + plan.slice(1).replaceAll("_", " ")
    }

    function windowTooltip(title, window) {
        const remaining = window ? window.remainingPercent + "%" : i18n("Unavailable")
        return title + " — " + remaining + "\n"
            + i18n("Resets: %1", root.resetAtLabel(window)) + "\n"
            + i18n("Resets in: %1", root.resetsInLabel(window))
    }

    function dialTooltip() {
        if (root.lastError) return root.lastError
        if (root.usage.status !== "ok") return i18n("Loading Codex usage…")
        return root.windowTooltip(i18n("5-hour limit"), root.usage.primary) + "\n\n"
            + root.windowTooltip(i18n("Weekly limit"), root.usage.secondary) + "\n\n"
            + i18n("Updated: %1", root.updatedAtLabel())
    }

    Plasma5Support.DataSource {
        id: limitsSource
        readonly property string command: "python3 \"" + root.helperPath + "\""
        engine: "executable"
        interval: root.refreshIntervalMs
        connectedSources: [command]

        onNewData: function(sourceName, data) {
            root.refreshing = false
            let output = String(data.stdout || "").trim()
            if (!output) {
                root.lastError = i18n("Codex returned no data")
                root.usage = ({status: "error"})
                return
            }
            try {
                const parsed = JSON.parse(output.split("\n").pop())
                root.usage = parsed
                root.lastError = parsed.status === "error" ? parsed.message : ""
            } catch (error) {
                root.lastError = i18n("Could not read the Codex response")
                root.usage = ({status: "error"})
            }
        }
    }

    Component.onCompleted: refresh()

    compactRepresentation: MouseArea {
        id: compact
        implicitWidth: compactGauges.implicitWidth + Kirigami.Units.smallSpacing * 2
        implicitHeight: Kirigami.Units.gridUnit * 2
        onClicked: root.expanded = !root.expanded

        RowLayout {
            id: compactGauges
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.smallSpacing
            anchors.rightMargin: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            PanelGauge {
                visible: Number(Plasmoid.configuration.panelDisplay) !== 1
                Layout.preferredWidth: compact.height
                Layout.fillHeight: true
                windowData: root.usage.primary
                gaugeColor: Plasmoid.configuration.fiveHourColor || "#3daee9"
                baseLabel: i18n("5h")
            }

            PanelGauge {
                visible: Number(Plasmoid.configuration.panelDisplay) !== 0
                Layout.preferredWidth: compact.height
                Layout.fillHeight: true
                windowData: root.usage.secondary
                gaugeColor: Plasmoid.configuration.weeklyColor || "#2ecc71"
                baseLabel: i18n("W")
            }
        }

    }

    fullRepresentation: Item {
        id: fullView

        implicitWidth: Kirigami.Units.gridUnit * 20
        implicitHeight: Plasmoid.formFactor === PlasmaCore.Types.Planar
            ? Kirigami.Units.gridUnit * 17
            : root.usage.status === "ok"
                ? panelDetails.implicitHeight + Kirigami.Units.smallSpacing * 2
                : Kirigami.Units.gridUnit * 8
        Layout.minimumHeight: Plasmoid.formFactor === PlasmaCore.Types.Planar
            ? 0 : implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: Plasmoid.formFactor === PlasmaCore.Types.Planar
            ? Number.POSITIVE_INFINITY : implicitHeight

        Item {
            id: dial
            visible: root.usage.status === "ok"
                && Plasmoid.formFactor === PlasmaCore.Types.Planar
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing

            Canvas {
                id: dialCanvas
                anchors.fill: parent
                property real primaryValue: root.usage.primary
                    ? root.usage.primary.remainingPercent : 0
                property real secondaryValue: root.usage.secondary
                    ? root.usage.secondary.remainingPercent : 0
                property color primaryColor: Plasmoid.configuration.fiveHourColor
                    || "#3daee9"
                property color secondaryColor: Plasmoid.configuration.weeklyColor
                    || "#2ecc71"
                property color trackColor: Kirigami.Theme.disabledTextColor

                onPrimaryValueChanged: requestPaint()
                onSecondaryValueChanged: requestPaint()
                onPrimaryColorChanged: requestPaint()
                onSecondaryColorChanged: requestPaint()
                onTrackColorChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                function drawGaugeArc(context, centerX, centerY, radius,
                    lineWidth, value, color) {
                    context.save()
                    context.translate(centerX, centerY)
                    context.lineWidth = lineWidth
                    context.lineCap = "round"
                    const startAngle = Math.PI * 0.75
                    const sweepAngle = Math.PI * 1.5

                    context.beginPath()
                    context.globalAlpha = 0.22
                    context.strokeStyle = trackColor
                    context.arc(0, 0, radius, startAngle,
                        startAngle + sweepAngle, false)
                    context.stroke()

                    if (value > 0) {
                        context.beginPath()
                        context.globalAlpha = 1
                        context.strokeStyle = color
                        context.arc(0, 0, radius, startAngle,
                            startAngle + sweepAngle * Math.min(100, value) / 100, false)
                        context.stroke()
                    }
                    context.restore()
                }

                onPaint: {
                    const context = getContext("2d")
                    context.clearRect(0, 0, width, height)
                    const centerX = width / 2
                    const centerY = height * 0.49
                    const outerRadius = Math.max(1, Math.min(width, height) * 0.42)
                    const ringWidth = Math.max(3, Math.min(width, height) * 0.026)
                    const gap = Math.max(10, ringWidth * 2.4)
                    drawGaugeArc(context, centerX, centerY, outerRadius, ringWidth,
                        primaryValue, primaryColor)
                    drawGaugeArc(context, centerX, centerY,
                        Math.max(1, outerRadius - gap), ringWidth,
                        secondaryValue, secondaryColor)
                }
            }

            Item {
                id: percentageLabels
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.43
                width: Math.min(parent.width, parent.height) * 0.42
                height: Math.max(5, Math.min(parent.width, parent.height) * 0.12)

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2 - 1
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: root.usage.primary ? root.usage.primary.remainingPercent + "%" : "--%"
                    color: Plasmoid.configuration.percentageColor || "#eff0f1"
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 3
                    font.weight: Font.Normal
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: parent.width / 2 - 1
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: root.usage.secondary ? root.usage.secondary.remainingPercent + "%" : "--%"
                    color: Plasmoid.configuration.percentageColor || "#eff0f1"
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.2
                    fontSizeMode: Text.Fit
                    minimumPixelSize: 3
                    font.weight: Font.Normal
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.75
                width: Math.min(parent.width, parent.height) * 0.46
                height: Math.max(6, Math.min(parent.width, parent.height) * 0.14)
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: i18n("Codex")
                color: dialCanvas.trackColor
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.3
                fontSizeMode: Text.Fit
                minimumPixelSize: 4
                font.weight: Font.Normal
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                QQC2.ToolTip.visible: containsMouse
                QQC2.ToolTip.text: root.dialTooltip()
            }
        }

        ColumnLayout {
            id: panelDetails
            visible: root.usage.status === "ok"
                && Plasmoid.formFactor !== PlasmaCore.Types.Planar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    text: root.planLabel(root.usage.planType)
                    color: Plasmoid.configuration.percentageColor || "#eff0f1"
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.15
                    font.weight: Font.Normal
                }

                Item { Layout.fillWidth: true }

                QQC2.Label {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: i18n("Updated %1", Qt.formatTime(
                        new Date(root.usage.fetchedAt * 1000), "h:mm:ss AP"))
                    color: Kirigami.Theme.disabledTextColor
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.weight: Font.Normal
                }
            }

            LimitInfoRow {
                Layout.fillWidth: true
                windowData: root.usage.primary
                accentColor: Plasmoid.configuration.fiveHourColor || "#3daee9"
                title: i18n("5-hour limit")
                shortLabel: i18n("5h")
                showSeparator: true
            }

            LimitInfoRow {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                windowData: root.usage.secondary
                accentColor: Plasmoid.configuration.weeklyColor || "#2ecc71"
                title: i18n("Weekly limit")
                shortLabel: i18n("W")
                showSeparator: false
            }

            Rectangle {
                visible: Boolean(root.usage.rateLimitReachedType)
                Layout.fillWidth: true
                implicitHeight: warningLabel.implicitHeight + Kirigami.Units.largeSpacing
                radius: Kirigami.Units.cornerRadius
                color: Kirigami.Theme.negativeBackgroundColor

                QQC2.Label {
                    id: warningLabel
                    anchors.fill: parent
                    anchors.margins: Kirigami.Units.smallSpacing
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    text: String(root.usage.rateLimitReachedType || "").replaceAll("_", " ")
                    color: Kirigami.Theme.negativeTextColor
                    font.weight: Font.Normal
                }
            }

        }

        ColumnLayout {
            visible: root.usage.status !== "ok"
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Kirigami.Icon {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Kirigami.Units.iconSizes.large
                    Layout.preferredHeight: width
                    source: root.refreshing ? "view-refresh" : "data-error"
                }
                QQC2.Label {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    text: root.refreshing ? i18n("Loading Codex usage…") : root.lastError
                }
                QQC2.Label {
                    visible: !root.refreshing
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.Wrap
                    color: Kirigami.Theme.disabledTextColor
                    text: i18n("Install the Codex CLI and run ‘codex login’.")
                }
            }
        }
    }

    component PanelGauge: Item {
        required property var windowData
        required property color gaugeColor
        required property string baseLabel
        readonly property real remaining: windowData ? windowData.remainingPercent : 0

        implicitWidth: Kirigami.Units.gridUnit * 2
        implicitHeight: Kirigami.Units.gridUnit * 2

        Canvas {
            id: panelCanvas
            anchors.fill: parent
            property real gaugeValue: parent.remaining
            property color arcColor: parent.gaugeColor
            property color trackColor: Kirigami.Theme.disabledTextColor

            onGaugeValueChanged: requestPaint()
            onArcColorChanged: requestPaint()
            onTrackColorChanged: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const context = getContext("2d")
                context.clearRect(0, 0, width, height)
                const centerX = width / 2
                const centerY = height * 0.48
                const radius = Math.max(1, Math.min(width, height) * 0.36)
                const lineWidth = Math.max(2, Math.min(width, height) * 0.055)
                const startAngle = Math.PI * 0.75
                const sweepAngle = Math.PI * 1.5

                context.lineWidth = lineWidth
                context.lineCap = "round"
                context.beginPath()
                context.globalAlpha = 0.22
                context.strokeStyle = trackColor
                context.arc(centerX, centerY, radius, startAngle,
                    startAngle + sweepAngle, false)
                context.stroke()

                if (gaugeValue > 0) {
                    context.beginPath()
                    context.globalAlpha = 1
                    context.strokeStyle = arcColor
                    context.arc(centerX, centerY, radius, startAngle,
                        startAngle + sweepAngle * Math.min(100, gaugeValue) / 100, false)
                    context.stroke()
                }
            }
        }

        QQC2.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.30
            text: root.lastError ? "!" : (parent.windowData
                ? parent.windowData.remainingPercent + "%" : "--%")
            color: root.lastError ? Kirigami.Theme.negativeTextColor
                : (Plasmoid.configuration.percentageColor || "#eff0f1")
            font.pixelSize: Math.max(7, parent.height * 0.24)
            font.weight: Font.Normal
        }

        QQC2.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.72
            text: parent.baseLabel
            color: Plasmoid.configuration.percentageColor || "#eff0f1"
            font.pixelSize: Math.max(6, parent.height * 0.18)
            font.weight: Font.Normal
        }
    }

    component LimitInfoRow: Item {
        id: infoRow

        required property var windowData
        required property color accentColor
        required property string title
        required property string shortLabel
        property bool showSeparator: true

        implicitHeight: Kirigami.Units.gridUnit * 3.4
            + (showSeparator ? Kirigami.Units.largeSpacing : 0)
        Layout.minimumHeight: implicitHeight
        Layout.preferredHeight: implicitHeight
        Layout.maximumHeight: implicitHeight

        RowLayout {
            anchors.fill: parent
            anchors.bottomMargin: infoRow.showSeparator
                ? Kirigami.Units.largeSpacing : 0
            spacing: Kirigami.Units.smallSpacing

            PanelGauge {
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                Layout.preferredHeight: Kirigami.Units.gridUnit * 3
                Layout.alignment: Qt.AlignVCenter
                windowData: infoRow.windowData
                gaugeColor: infoRow.accentColor
                baseLabel: infoRow.shortLabel
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    text: infoRow.title
                    color: infoRow.accentColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.weight: Font.Normal
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    text: i18n("Resets: %1", root.resetAtLabel(infoRow.windowData))
                    color: Kirigami.Theme.textColor
                    font.weight: Font.Normal
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignLeft
                    text: i18n("Resets in: %1", root.resetsInLabel(infoRow.windowData))
                    color: Kirigami.Theme.disabledTextColor
                    font.weight: Font.Normal
                }
            }
        }

        Rectangle {
            visible: infoRow.showSeparator
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Kirigami.Theme.disabledTextColor
            opacity: 0.25
        }
    }
}
