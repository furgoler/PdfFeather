/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation
*/

import QtQuick
import QtCore
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtQuick.Pdf

ApplicationWindow {
    id: root
    width: 1150
    height: 700
    property string appname: "Pdf Feather"
    title: (doc.source.toString() === "") ? root.appname : doc.title + ' [' + filename(doc.source.toString()) + ']'
    visible: true

    // Properties for C++
    property string source: ""
    // See also "pdfattachmentmodel" and "pdfmanager"

    // General configuration parameters
    // Drawer ScrollBar: Not shown scrollbar (ScrollBar.AlwaysOff), but it can be controlled with the wheel.
    // Other available choices: (ScrollBar.AsNeeded, ScrollBar.AlwaysOff, ScrollBar.AlwaysOn)
    property int drawer_scrollbar_policy: ScrollBar.AlwaysOff

    // Style parameters
    // Note this is only used for changes beetween dark and light themes. Other configuration are in qtquickcontrols2.conf file
    Material.theme: Material.Dark // Can be either Dark or Light

    // ********** Settings Paramters ***********
    Settings {
        id: appThemeSettings
        category: "Interface"
        property int theme
    }
    Settings {
        id: appAttachmentSettings
        category: "Attachments"
        property int policy
        property string header
    }

    Component.onCompleted: {
            // On launch, read theme from settings file (used value method to define a default property)
            root.Material.theme = appThemeSettings.value("theme", 0)
            configdialog.theme = root.Material.theme

            configdialog.attachPolicy = appAttachmentSettings.value("policy", 1)
            configdialog.attachHeader = appAttachmentSettings.value("header", qsTr("Embedded Content:"))
            pdfmanager.setAttachmentPolicy(configdialog.attachPolicy)
            pdfmanager.setHeaderText(configdialog.attachHeader)
        }

    Component.onDestruction:{
        // On close, write theme to settings file
        appThemeSettings.theme = root.Material.theme
        appAttachmentSettings.policy = configdialog.attachPolicy
        appAttachmentSettings.header = configdialog.attachHeader
    }

    // ********** GUI ***********
    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.rightMargin: 6
            ToolButton {
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Open pdf")
                action: Action {
                    shortcut: StandardKey.Open
                    icon.source: "qrc:/images/open.svg"
                    onTriggered: openpdffileDialog.open()
                }
            }
            ToolButton {
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Save pdf")
                action: Action {
                    shortcut: StandardKey.Save
                    enabled: pdfmanager ? !pdfmanager.saved : false
                    icon.source: "qrc:/images/save.svg"
                    onTriggered: savepdffileDialog.open()
                }
            }
            ToolButton {
                id: btnAttach
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Attachments")
                action: Action {
                    enabled: true
                    icon.source: "qrc:/images/attach.svg"
                    onTriggered: {
                        // At this menu is open in mouse position when used as context menu
                        // For the toolbar, it is used the default 0,0 position
                        contextMenuAttachments.x = btnAttach.x;
                        contextMenuAttachments.y = 0;
                        contextMenuAttachments.open()
                    }
                }
            }
            ToolSeparator {}
            RowLayout {
                enabled: doc.source !== Qt.resolvedUrl("")
                ToolButton {
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Zoom In")
                    //enabled: doc.source !== Qt.resolvedUrl("")
                    action: Action {
                        shortcut: StandardKey.ZoomIn
                        //enabled: view.renderScale < 10
                        enabled: cmbZoom.currentIndex >= 2 && cmbZoom.currentIndex < 12
                        icon.source: "qrc:/images/zoom-in.svg"
                        //onTriggered: view.renderScale *= Math.sqrt(2)
                        onTriggered: cmbZoom.currentIndex += 1
                    }
                }
                ComboBox {
                    id: cmbZoom
                    editable: false
                    //enabled: doc.source !== Qt.resolvedUrl("")
                    popup.closePolicy: Popup.CloseOnEscape
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Zoom")
                    model: ListModel {
                        id: model
                        ListElement { text: qsTr("Fit Width") }
                        ListElement { text: qsTr("Fit Page") }
                        ListElement { text: "12%" }
                        ListElement { text: "25%" }
                        ListElement { text: "33%" }
                        ListElement { text: "50%" }
                        ListElement { text: "66%" }
                        ListElement { text: "75%" }
                        ListElement { text: "100%" }
                        ListElement { text: "125%" }
                        ListElement { text: "150%" }
                        ListElement { text: "200%" }
                        ListElement { text: "400%" }
                    }
                    currentIndex: 8 // 100% Initial Value
                    onCurrentIndexChanged: {
                        if (currentIndex === 0) view.scaleToWidth(root.contentItem.width, root.contentItem.height) // Fit width
                        else if (currentIndex === 1) view.scaleToPage(root.contentItem.width, root.contentItem.height) // Fit page
                        else view.renderScale = parseInt(textAt(currentIndex)) / 100 // currentValue return previous value, so used currentIndex
                        //console.log("Scale: " + view.renderScale)                        
                    }
                }
                ToolButton {
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Zoom Out")
                    //enabled: doc.source !== Qt.resolvedUrl("")
                    action: Action {
                        shortcut: StandardKey.ZoomOut
                        //enabled: view.renderScale > 0.1
                        enabled: cmbZoom.currentIndex > 2 && cmbZoom.currentIndex <= 12
                        icon.source: "qrc:/images/zoom-out.svg"
                        //onTriggered: view.renderScale /= Math.sqrt(2)
                        onTriggered: cmbZoom.currentIndex -= 1
                    }
                }                
            }
            RowLayout {
                enabled: doc.source !== Qt.resolvedUrl("")
                ToolButton {
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Previous Page")
                    action: Action {
                        icon.source: "qrc:/images/page-previous.svg"
                        onTriggered: {
                            currentPageSB.value -= 1
                            view.goToPage(currentPageSB.value -1)
                        }
                    }
                }
                SpinBox {
                    id: currentPageSB
                    from: 1
                    to: doc.pageCount
                    editable: true
                    onValueModified: view.goToPage(value - 1)
                    down.indicator : Item {}  // Hide Down indicator
                    up.indicator : Item {}    // Hide Up indicator
                    Shortcut {
                        sequence: StandardKey.MoveToPreviousPage
                        onActivated: view.goToPage(currentPageSB.value - 2)
                    }
                    Shortcut {
                        sequence: StandardKey.MoveToNextPage
                        onActivated: view.goToPage(currentPageSB.value)
                    }
                }
                ToolButton {
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Next Page")
                    action: Action {
                        icon.source: "qrc:/images/page-next.svg"
                        onTriggered: {
                            currentPageSB.value += 1
                            view.goToPage(currentPageSB.value - 1)
                        }
                    }
                }
                ToolButton {
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Previous View")
                    action: Action {
                        icon.source: "qrc:/images/go-previous-view-page.svg"
                        enabled: view.backEnabled
                        onTriggered: view.back()
                    }
                }
                ToolButton {
                    ToolTip.visible: enabled && hovered
                    ToolTip.delay: 1000
                    ToolTip.text: qsTr("Next View")
                    action: Action {
                        icon.source: "qrc:/images/go-next-view-page.svg"
                        enabled: view.forwardEnabled
                        onTriggered: view.forward()
                    }
                }
            }
            ToolSeparator {}
            ToolButton {
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Select All")
                enabled: doc.source !== Qt.resolvedUrl("")
                action: Action {
                    shortcut: StandardKey.SelectAll
                    icon.source: "qrc:/images/edit-select-all.svg"
                    onTriggered: view.selectAll()
                }
            }
            ToolButton {
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Copy")
                action: Action {
                    shortcut: StandardKey.Copy
                    icon.source: "qrc:/images/edit-copy.svg"
                    enabled: view.selectedText !== ""
                    onTriggered: view.copySelectionToClipboard()
                }
            }
            ToolSeparator {}
            ToolButton {
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Settings")
                action: Action {
                    icon.source: "qrc:/images/settings.svg"
                    onTriggered: configdialog.open()
                }
            }
            ToolButton {
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("About")
                action: Action {
                    icon.source: "qrc:/images/about.svg"
                    onTriggered: aboutdialog.open()
                }
            }
            Shortcut {
                sequence: StandardKey.Find
                onActivated: searchField.forceActiveFocus()
            }
            Shortcut {
                sequence: StandardKey.Quit
                onActivated: Qt.quit()
            }
        }
    }

    FileDialog {
        id: openpdffileDialog
        title: qsTr("Open a PDF file")
        nameFilters: [ qsTr("PDF files (*.pdf)") ]
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            // reset previous doc and pwd (required for resetting pwd properly)
            resetpdf()
            // load new file
            doc.source = selectedFile
        }
    }

    FileDialog {
        id: savepdffileDialog
        title: qsTr("Save a PDF file")
        nameFilters: [ qsTr("PDF files (*.pdf)") ]
        fileMode: FileDialog.SaveFile
        options: FileDialog.DontConfirmOverwrite
        currentFolder: Qt.resolvedUrl("") ? basename(doc.source.toString()) : StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            if (selectedFile == doc.source) {
                genericDialog.title = qsTr("Error")
                genericDialog.dlgmessage = qsTr("Please, select another output. \nCurrent pdf file cannot be overwritten")
                genericDialog.open()
                return
            }
            if (!pdfmanager.savePdf(selectedFile)) {
                genericDialog.title = qsTr("Error")
                genericDialog.dlgmessage = qsTr("Error saving ") + qsTr("'") + filename(url2file(selectedFile)) + qsTr("'")
                genericDialog.open()
            }
            else {
                genericDialog.title = qsTr("Information")
                genericDialog.dlgmessage = qsTr("'") + filename(url2file(selectedFile)) + qsTr("'") + qsTr(" is sucessfully saved")
                genericDialog.open()
            }
        }
    }

    FileDialog {
        id: addEmbedFilesDialog
        title: qsTr("Embed files")
        nameFilters: [ qsTr("All files (*.*)") ]
        fileMode: FileDialog.OpenFiles
        currentFolder: doc.source !== Qt.resolvedUrl("") ? basename(doc.source.toString()) : StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            var dropped_file_keys = []  // Keys of files dropped
            for (var i = 0; i < selectedFiles.length; i++) {
                dropped_file_keys.push(filename(selectedFiles[i].toString()));
            }
            var existing_keys = pdfattachmentmodel.getData().filter(x => dropped_file_keys.includes(x));
            if (existing_keys.length > 0) {
                overwriteDialog.urls = selectedFiles;
                overwriteDialog.open();
            }
            else pdfmanager.addEmbedFiles(selectedFiles);
        }
    }

    FolderDialog  {
        id: selectpathDialog
        property string custom_action
        title: qsTr("Select a Folder")
        currentFolder: Qt.resolvedUrl("") ? basename(doc.source.toString()) : StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            console.log(selectedFolder)
            switch (custom_action) {
                case "save":
                       pdfmanager.saveEmbedFile(pdfattachmentmodel.getData()[attachmentList.currentIndex], selectedFolder)
                    break
                case "saveall":
                    pdfmanager.saveAllEmbedFiles(selectedFolder)
                    break
            }
        }
    }

    Dialog {
        id: passwordDialog
        title: qsTr("Password")
        standardButtons: Dialog.Ok | Dialog.Cancel
        modal: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent
        width: 300

        contentItem: TextField {
            id: passwordField
            width: parent ? parent.width : implicitWidth
            placeholderText: qsTr("Please, provide the password")
            echoMode: TextInput.Password           
            onAccepted: passwordDialog.accept()
        }
        onOpened: passwordField.forceActiveFocus()
        onAccepted: doc.password = passwordField.text
    }

    Dialog {
        id: overwriteDialog
        property list<url> urls
        title: qsTr("Warning")
        standardButtons: Dialog.YesToAll | Dialog.Abort
        modal: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent

        contentItem: Label {
            id: overwriteattachments
            width: parent ? parent.width : implicitWidth
            text: qsTr("Attachments already exists.\n") + qsTr("Replace embedded files?")
        }
        onAccepted: pdfmanager.addEmbedFiles(urls)
    }

    Dialog {
        id: errorPdfDialog
        title: "Error"
        standardButtons: Dialog.Close
        modal: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent
        visible: doc.status === PdfDocument.Error

        contentItem: Label {
            id: errorField
            width: parent ? parent.width : implicitWidth
            //text: doc.error
            text: doc.error.charAt(0).toUpperCase() + doc.error.slice(1)
        }
    }

    Dialog {
        id: genericDialog
        property string dlgmessage
        title: ""
        standardButtons: Dialog.Close
        modal: true
        closePolicy: Popup.CloseOnEscape
        anchors.centerIn: parent
        contentItem: Label {
            width: parent ? parent.width : implicitWidth
            text: genericDialog.dlgmessage
        }
    }

    ConfigFeather {
        id: configdialog
        onAccepted: {
            pdfmanager.setAttachmentPolicy(configdialog.attachPolicy)
            pdfmanager.setHeaderText(configdialog.attachHeader)
            root.Material.theme = configdialog.theme
        }
    }

    About {id: aboutdialog}

    Menu {
            id: contextMenuAttachments
            MenuItem {
                text: qsTr("Open")
                enabled: attachmentList.currentIndex !== -1
                onTriggered: {
                    pdfmanager.openEmbedFile(pdfattachmentmodel.getData()[attachmentList.currentIndex])
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Add")
                enabled: true
                onTriggered: {
                    addEmbedFilesDialog.open()
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Remove")
                enabled: attachmentList.currentIndex !== -1
                onTriggered: {
                    pdfmanager.removeEmbedFile(pdfattachmentmodel.getData()[attachmentList.currentIndex])
                }
            }
            MenuItem {
                text: qsTr("Remove All")
                enabled: attachmentList.count > 0
                onTriggered: {
                    pdfmanager.removeEmbedFiles(pdfattachmentmodel.getData())
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Save")
                enabled: attachmentList.currentIndex !== -1
                onTriggered: {
                    selectpathDialog.custom_action = "save"
                    selectpathDialog.open()
                }
            }
            MenuItem {
                text: qsTr("Save All")
                enabled: attachmentList.count > 0
                onTriggered: {
                    selectpathDialog.custom_action = "saveall"
                    selectpathDialog.open()
                }
            }
        }

    PdfDocument {
        id: doc
        source: Qt.resolvedUrl(root.source)
        onPasswordRequired: passwordDialog.open()

        onStatusChanged: function(status) {
            if (status === PdfDocument.Ready) {
                console.log("QML PdfDocument Ready: " + source)
                pdfmanager.loadPdf(source, password)
            }
        }
    }

    PdfMultiPageView {
        id: view
        anchors.fill: parent
        anchors.leftMargin: sidebar.position * sidebar.width
        document: doc
        searchString: searchField.text
        onCurrentPageChanged: currentPageSB.value = view.currentPage + 1        
    }

    DropArea {
        id: pdfDropArea
        anchors.fill: view
        keys: ["text/uri-list"]
        onEntered: (drag) => {
            drag.accepted = (drag.proposedAction === Qt.MoveAction || drag.proposedAction === Qt.CopyAction) &&
                drag.hasUrls && drag.urls[0].toString().endsWith(".pdf")            
        }
        onDropped: (drop) => {
            // reset previous doc and pwd (required for resetting pwd properly)
            resetpdf()
            // load new file
            doc.source = drop.urls[0]
            drop.acceptProposedAction()            
        }
    }    

    Drawer {
        id: sidebar
        edge: Qt.LeftEdge
        modal: false
        width: 300
        y: root.header.height
        height: view.height
        dim: false
        clip: true
        closePolicy: Popup.NoAutoClose

        TabBar {
            id: sidebarTabs
            x: -width
            rotation: -90
            transformOrigin: Item.TopRight
            currentIndex: 3 // bookmarks by default
            TabButton {
                text: qsTr("Info")
            }
            TabButton {
                text: qsTr("Search Results")
            }
            TabButton {
                text: qsTr("Attachments")
            }
            TabButton {
                text: qsTr("Bookmarks")
            }
            TabButton {
                text: qsTr("Pages")
            }
        }

        GroupBox {
            anchors.fill: parent
            anchors.leftMargin: sidebarTabs.height

            StackLayout {
                anchors.fill: parent
                currentIndex: sidebarTabs.currentIndex

                ScrollView {
                    id: scrollview
                    Layout.fillHeight: true
                    Layout.fillWidth: true                    
                    ScrollBar.vertical.policy: root.drawer_scrollbar_policy
                    clip: true
                    ColumnLayout {
                        spacing: 6
                        width: Math.max(implicitWidth, scrollview.availableWidth) - spacing
                        Layout.fillHeight: true
                        Label { font.bold: true; text: qsTr("Title") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.title
                            onEditingFinished: pdfmanager.replaceMetadata("Title", text)
                        }
                        Label { font.bold: true; text: qsTr("Author") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.author
                            onEditingFinished: pdfmanager.replaceMetadata("Author", text)
                        }
                        Label { font.bold: true; text: qsTr("Subject") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.subject
                            onEditingFinished: pdfmanager.replaceMetadata("Subject", text)
                        }
                        Label { font.bold: true; text: qsTr("Keywords") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.keywords
                            onEditingFinished: pdfmanager.replaceMetadata("Keywords", text)
                        }
                        Label { font.bold: true; text: qsTr("Producer") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.producer
                            onEditingFinished: pdfmanager.replaceMetadata("Producer", text)
                        }
                        Label { font.bold: true; text: qsTr("Creator") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.creator
                            onEditingFinished: pdfmanager.replaceMetadata("Creator", text)
                        }
                        Label { font.bold: true; text: qsTr("Creation date") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.creationDate
                            enabled: false
                        }
                        Label { font.bold: true; text: qsTr("Modification date") }
                        TextField {
                            Layout.fillWidth: true
                            text: doc.modificationDate
                            enabled: false
                        }
                    }
                }
                ListView {
                    id: searchResultsList
                    implicitHeight: parent.height
                    spacing: 2
                    model: view.searchModel
                    currentIndex: view.searchModel.currentResult
                    ScrollBar.vertical: ScrollBar { policy: root.drawer_scrollbar_policy }
                    delegate: ItemDelegate {
                        id: resultDelegate
                        required property int index
                        required property int page
                        required property string contextBefore
                        required property string contextAfter
                        width: parent ? parent.width : 0
                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            Label {
                                text: qsTr("Page ") + (resultDelegate.page + 1) + ": "
                            }
                            Label {
                                text: resultDelegate.contextBefore
                                elide: Text.ElideLeft
                                horizontalAlignment: Text.AlignRight
                                Layout.fillWidth: true
                                Layout.preferredWidth: parent.width / 2
                            }
                            Label {
                                font.bold: true
                                text: view.searchString
                                width: implicitWidth
                            }
                            Label {
                                text: resultDelegate.contextAfter
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                Layout.preferredWidth: parent.width / 2
                            }
                        }
                        highlighted: ListView.isCurrentItem
                        onClicked: view.searchModel.currentResult = resultDelegate.index
                    }
                }
                ListView {
                    id: attachmentList
                    implicitHeight: parent.height
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: 2
                    model: pdfattachmentmodel
                    currentIndex: -1
                    ScrollBar.vertical: ScrollBar { policy: root.drawer_scrollbar_policy }
                    delegate: ItemDelegate  {
                        implicitWidth: parent ? parent.width : 100
                        highlighted: ListView.isCurrentItem
                        checkable: false
                        Label {
                            text: model.display
                            width: parent.width
                            elide: Text.ElideRight
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: 0
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: (mouse)=> {
                                attachmentList.currentIndex = index
                                if (mouse.button === Qt.RightButton) contextMenuAttachments.popup()
                            }
                            onDoubleClicked: {
                                pdfmanager.openEmbedFile(pdfattachmentmodel.getData()[index])
                            }
                        }

                    }
                    MouseArea {
                        anchors.fill: parent
                        z: -1 // To allow this ListView MouseArea below its child ItemDelegate MouseArea
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse)=> {
                            attachmentList.currentIndex = -1
                            if (mouse.button === Qt.RightButton) contextMenuAttachments.popup()
                        }
                    }

                    DropArea {
                        id: attachmentsDropArea
                        anchors.fill: attachmentList
                        keys: ["text/uri-list"]
                        onEntered: (drag) => {
                            drag.accepted = (drag.proposedAction === Qt.MoveAction || drag.proposedAction === Qt.CopyAction) && drag.hasUrls
                        }
                        onDropped: (drop) => {
                            var dropped_file_keys = []  // Keys of files dropped
                            for (var i = 0; i < drop.urls.length; i++) {
                                dropped_file_keys.push(filename(drop.urls[i].toString()));
                            }
                            var existing_keys = pdfattachmentmodel.getData().filter(x => dropped_file_keys.includes(x));
                            if (existing_keys.length > 0) {
                                overwriteDialog.urls = drop.urls;
                                overwriteDialog.open();
                            }
                            else pdfmanager.addEmbedFiles(drop.urls);
                        }
                    }                    
                }                
                TreeView {
                    id: bookmarksTree
                    implicitHeight: parent.height
                    implicitWidth: parent.width
                    columnWidthProvider: function() { return width }
                    delegate: TreeViewDelegate {
                        required property int page
                        required property point location
                        required property real zoom
                        background: Rectangle { color: "transparent" } // Override Control to make background as theme
                        onClicked: view.goToLocation(page, location, zoom)                        
                    }                    
                    model: PdfBookmarkModel {
                        document: doc
                    }
                    ScrollBar.vertical: ScrollBar { policy: root.drawer_scrollbar_policy }
                }                
                GridView {
                    id: thumbnailsView
                    implicitWidth: parent.width
                    implicitHeight: parent.height
                    model: doc.pageModel
                    cellWidth: width / 2
                    cellHeight: cellWidth + 10
                    delegate: Item {
                        required property int index
                        required property string label
                        required property size pointSize
                        width: thumbnailsView.cellWidth
                        height: thumbnailsView.cellHeight
                        Rectangle {
                            id: paper
                            width: image.width
                            height: image.height
                            x: (parent.width - width) / 2
                            y: (parent.height - height - pageNumber.height) / 2
                            PdfPageImage {
                                id: image
                                document: doc
                                currentFrame: index
                                asynchronous: true
                                fillMode: Image.PreserveAspectFit
                                property bool landscape: pointSize.width > pointSize.height
                                width: landscape ? thumbnailsView.cellWidth - 6
                                                 : height * pointSize.width / pointSize.height
                                height: landscape ? width * pointSize.height / pointSize.width
                                                  : thumbnailsView.cellHeight - 14
                                sourceSize.width: width
                                sourceSize.height: height
                            }
                        }
                        Label {
                            id: pageNumber
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: label
                        }
                        TapHandler {
                            onTapped: view.goToPage(index)
                        }
                    }
                }
            }
        }
    }

    footer: ToolBar {
        height: footerRow.implicitHeight + 6
        RowLayout {
            id: footerRow
            anchors.fill: parent
            ToolButton {
                action: Action {
                    id: sidebarOpenAction
                    checkable: true
                    checked: sidebar.opened
                    icon.source: checked ? "qrc:/images/sidebar-collapse-left.svg" : "qrc:/images/sidebar-expand-left.svg"
                    onTriggered: sidebar.visible = !sidebar.visible
                }
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: checked ? qsTr("Close Sidebar") : qsTr("Open Sidebar")
            }
            ToolButton {
                action: Action {
                    icon.source: "qrc:/images/go-up-search.svg"
                    shortcut: StandardKey.FindPrevious
                    onTriggered: view.searchBack()
                }
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Find Previous")
            }
            TextField {
                id: searchField
                placeholderText: qsTr("Search")
                Layout.minimumWidth: 150
                Layout.fillWidth: true
                Layout.bottomMargin: 3
                onAccepted: {
                    sidebar.open()
                    sidebarTabs.setCurrentIndex(1)
                }                
            }
            ToolButton {
                action: Action {
                    icon.source: "qrc:/images/go-down-search.svg"
                    shortcut: StandardKey.FindNext
                    onTriggered: view.searchForward()
                }
                ToolTip.visible: enabled && hovered
                ToolTip.delay: 1000
                ToolTip.text: qsTr("Find Next")
            }
            Label {
                id: statusLabel
                horizontalAlignment: Text.AlignRight
                text: qsTr("Page ") + (currentPageSB.value) + qsTr(" of ") + doc.pageCount
                visible: doc.pageCount > 0
            }
        }
    }

    // Custom JavaScript functions

    function url2file(str) {
        // remove prefixed "file:///" or "http://"
        var path = str.toString().replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"");
        // unescape html codes like '%23' for '#'
        var cleanPath = decodeURIComponent(path);
        return cleanPath;
    }

    function filename(str) {
        return (str.slice(str.lastIndexOf("/")+1))
    }

    function basename(str) {
        return (str.slice(0, str.lastIndexOf("/")))
    }

    function resetpdf() {
        doc.source = Qt.resolvedUrl("")
        doc.password = ""
        cmbZoom.currentIndex = 8 // Zoom 100%
    }
}


