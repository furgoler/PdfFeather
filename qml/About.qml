/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.qmlmodels

Dialog {
    id: root
    title: qsTr("About")
    anchors.centerIn: parent
    standardButtons: Dialog.Close
    closePolicy: Popup.CloseOnEscape

    property var columnWidths: [120, 150, 350, 250]
    property var columnNames: [qsTr("Item"), qsTr("Version"), qsTr("License"), qsTr("Url")]

    TableModel {
        id: myappmodel
        TableModelColumn { display: "item" }
        TableModelColumn { display: "version" }
        TableModelColumn { display: "license" }
        TableModelColumn { display: "url" }

        rows: [
            {
                "item": "Pdf Feather",
                "version": "1.2.2 (build 2023)",
                "license": "https://www.gnu.org/licenses/gpl-3.0.en.html",
                "url": ""
            }
        ]
    }

    TableModel {
        id: my3rdpartymodel
        TableModelColumn { display: "item" }
        TableModelColumn { display: "version" }
        TableModelColumn { display: "license" }
        TableModelColumn { display: "url" }

        rows: [
            {
                "item": "QT",
                "version": "6.5.0",
                "license": "LGPL v3",
                "url": "https://www.qt.io  "
            },
            {
                "item": "QPDF",
                "version": "11.3.0",
                "license": "Apache v2.0",
                "url": "https://qpdf.sourceforge.io"
            }
        ]
    }

    ColumnLayout {
        anchors.fill: parent

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Information")
        }

        HorizontalHeaderView {
            id: horizontalAppHeader
            syncView: appTableView
            model: root.columnNames
            resizableColumns: false
            boundsBehavior: Flickable.StopAtBounds
        }

        TableView {
            id: appTableView
            Layout.fillWidth: true
            implicitWidth: root.columnWidths[0] + root.columnWidths[1] + root.columnWidths[2] + root.columnWidths[3] + root.columnWidths.length * appTableView.columnSpacing
            implicitHeight: horizontalAppHeader.implicitHeight + myappmodel.rowCount * horizontalAppHeader.implicitHeight
            columnSpacing: 1
            rowSpacing: 1
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            columnWidthProvider: function (column) { return root.columnWidths[column] }

            model: myappmodel

            delegate: Label {
                text: display
                Layout.fillWidth: true
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            text: qsTr("Third party Libraries")
        }

        HorizontalHeaderView {
            id: horizontalThirdHeader
            syncView: thirdTableView
            model: root.columnNames
            resizableColumns: false
            boundsBehavior: Flickable.StopAtBounds
        }

        TableView {
            id: thirdTableView
            Layout.fillWidth: true
            implicitWidth: root.columnWidths[0] + root.columnWidths[1] + root.columnWidths[2] + root.columnWidths[3] + root.columnWidths.length * appTableView.columnSpacing
            implicitHeight: horizontalThirdHeader.implicitHeight + my3rdpartymodel.rowCount * horizontalThirdHeader.implicitHeight
            columnSpacing: 1
            rowSpacing: 1
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            columnWidthProvider: function (column) { return root.columnWidths[column] }

            model: my3rdpartymodel

            delegate: Label {
                text: display
                Layout.fillWidth: true
            }
        }

        Image {
            Layout.preferredWidth: 166
            Layout.preferredHeight: 140
            Layout.alignment: Qt.AlignHCenter
            source: "qrc:/images/furgoler.png"
            fillMode: Image.PreserveAspectFit
        }
    }
}


