import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid

Kirigami.FormLayout {
    id: root

    property alias cfg_refreshIntervalSeconds: refreshInterval.value
    property alias cfg_panelDisplay: panelDisplay.currentIndex
    property alias cfg_notificationsEnabled: notificationsEnabled.checked
    property alias cfg_resetNotificationsEnabled: resetNotificationsEnabled.checked
    property alias cfg_availabilityNotificationsEnabled: availabilityNotificationsEnabled.checked
    property alias cfg_fiveHourWarningEnabled: fiveHourWarningEnabled.checked
    property alias cfg_fiveHourWarningThreshold: fiveHourWarningThreshold.value
    property alias cfg_weeklyWarningEnabled: weeklyWarningEnabled.checked
    property alias cfg_weeklyWarningThreshold: weeklyWarningThreshold.value
    property string cfg_fiveHourColor: "#3daee9"
    property string cfg_weeklyColor: "#2ecc71"
    property string cfg_percentageColor: "#eff0f1"
    property int colorTarget: 0
    readonly property bool isDesktop: Plasmoid.formFactor === PlasmaCore.Types.Planar

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        text: i18n("General")
        level: 2
    }

    QQC2.SpinBox {
        id: refreshInterval
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 1
        to: 3600
        editable: true
        textFromValue: function(value, locale) {
            return i18np("%1 second", "%1 seconds", value)
        }
        valueFromText: function(text, locale) {
            const parsed = parseInt(text)
            return isNaN(parsed) ? 10 : parsed
        }
    }

    QQC2.ComboBox {
        id: panelDisplay
        visible: !root.isDesktop
        Kirigami.FormData.label: i18n("Panel shows:")
        model: [
            i18n("5-hour limit"),
            i18n("Weekly limit"),
            i18n("Both limits")
        ]
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        text: i18n("Notifications")
        level: 2
    }

    QQC2.CheckBox {
        id: notificationsEnabled
        Kirigami.FormData.label: i18n("Desktop notifications:")
        text: i18n("Enabled")
    }

    QQC2.CheckBox {
        id: resetNotificationsEnabled
        enabled: notificationsEnabled.checked
        text: i18n("Notify when a limit resets")
    }

    QQC2.CheckBox {
        id: availabilityNotificationsEnabled
        enabled: notificationsEnabled.checked
        text: i18n("Notify when usage is available again")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("5-hour warning:")
        enabled: notificationsEnabled.checked

        QQC2.CheckBox {
            id: fiveHourWarningEnabled
            text: i18n("Enabled at")
        }

        QQC2.SpinBox {
            id: fiveHourWarningThreshold
            enabled: fiveHourWarningEnabled.checked
            from: 1
            to: 99
            editable: true
            textFromValue: function(value, locale) {
                return i18n("%1% remaining", value)
            }
            valueFromText: function(text, locale) {
                const parsed = parseInt(text)
                return isNaN(parsed) ? 20 : parsed
            }
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Weekly warning:")
        enabled: notificationsEnabled.checked

        QQC2.CheckBox {
            id: weeklyWarningEnabled
            text: i18n("Enabled at")
        }

        QQC2.SpinBox {
            id: weeklyWarningThreshold
            enabled: weeklyWarningEnabled.checked
            from: 1
            to: 99
            editable: true
            textFromValue: function(value, locale) {
                return i18n("%1% remaining", value)
            }
            valueFromText: function(text, locale) {
                const parsed = parseInt(text)
                return isNaN(parsed) ? 20 : parsed
            }
        }
    }

    Kirigami.Heading {
        Kirigami.FormData.isSection: true
        text: root.isDesktop ? i18n("Desktop appearance") : i18n("Panel appearance")
        level: 2
    }

    RowLayout {
        Kirigami.FormData.label: i18n("5-hour color:")

        Rectangle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit
            radius: Kirigami.Units.cornerRadius
            color: root.cfg_fiveHourColor
            border.color: Kirigami.Theme.textColor
            border.width: 1
        }

        QQC2.Button {
            text: i18n("Choose…")
            onClicked: {
                root.colorTarget = 0
                colorDialog.selectedColor = root.cfg_fiveHourColor
                colorDialog.open()
            }
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Weekly color:")

        Rectangle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit
            radius: Kirigami.Units.cornerRadius
            color: root.cfg_weeklyColor
            border.color: Kirigami.Theme.textColor
            border.width: 1
        }

        QQC2.Button {
            text: i18n("Choose…")
            onClicked: {
                root.colorTarget = 1
                colorDialog.selectedColor = root.cfg_weeklyColor
                colorDialog.open()
            }
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Percentage color:")

        Rectangle {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit
            radius: Kirigami.Units.cornerRadius
            color: root.cfg_percentageColor
            border.color: Kirigami.Theme.textColor
            border.width: 1
        }

        QQC2.Button {
            text: i18n("Choose…")
            onClicked: {
                root.colorTarget = 2
                colorDialog.selectedColor = root.cfg_percentageColor
                colorDialog.open()
            }
        }
    }

    ColorDialog {
        id: colorDialog
        title: root.colorTarget === 0 ? i18n("Choose 5-hour color")
            : root.colorTarget === 1 ? i18n("Choose weekly color")
            : i18n("Choose percentage color")
        onAccepted: {
            if (root.colorTarget === 0) {
                root.cfg_fiveHourColor = selectedColor.toString()
            } else if (root.colorTarget === 1) {
                root.cfg_weeklyColor = selectedColor.toString()
            } else {
                root.cfg_percentageColor = selectedColor.toString()
            }
        }
    }
}
