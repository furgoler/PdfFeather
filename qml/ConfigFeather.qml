/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Dialog {
    id: root
    title: qsTr("Settings")
    anchors.centerIn: parent

    // Interface
    property int theme: 0

    // Attacments
    property int attachPolicy: 0
    property string attachHeader: ""

    // Emit signal accepted() as the own Dialog itself

    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true
    closePolicy: Popup.CloseOnEscape

    ColumnLayout {
        anchors.fill: parent

        TabBar {
            id: control

            TabButton {
                text: qsTr("Interface")
            }
            TabButton {
                text: qsTr("Attachments")
            }            
        }

        StackLayout {
            currentIndex: control.currentIndex
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Label {
                    text: qsTr("Theme:")
                }
                Switch {
                    id: themeSwitch
                    checked: (root.theme == 1)
                    text: checked ? qsTr("Dark") : qsTr("Light")
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Label {
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("Add list of embbeded files at the end:")
                }
                RadioButton {
                    id: rbnever
                    checked: (root.attachPolicy == 0)
                    text: qsTr("Never")
                }
                RadioButton {
                    id: rbnew
                    checked: (root.attachPolicy == 1)
                    text: qsTr("Only for new pdf")
                }
                RadioButton {
                    id: rbalways
                    checked: (root.attachPolicy == 2)
                    text: qsTr("Always")
                }
                Label {
                    text: "\nIntroduction for the list"
                }
                TextField {
                    id: tfheader
                    enabled: !rbnever.checked
                    Layout.fillWidth: true
                    text: root.attachHeader
                }
            }
        }
    }
    onAccepted: {
        if (rbnever.checked) root.attachPolicy = 0
        if (rbnew.checked) root.attachPolicy = 1
        if (rbalways.checked) root.attachPolicy = 2
        root.attachHeader = tfheader.text
        root.theme = themeSwitch.checked ? 1 : 0
        // Not required to emit signal accepted again as it is emitted by QML by default
    }

    onRejected: {
        rbnever.checked = (root.attachPolicy == 0)
        rbnew.checked = (root.attachPolicy == 1)
        rbalways.checked = (root.attachPolicy == 2)
        tfheader.text = root.attachHeader
        themeSwitch.checked = (root.theme == 1)
    }
}
