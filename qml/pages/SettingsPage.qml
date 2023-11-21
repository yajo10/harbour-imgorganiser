import QtQuick 2.6
import Sailfish.Silica 1.0
import QtFeedback 5.0


Dialog {
    id: pageSettings
    allowedOrientations: Orientation.Portrait
    canAccept: visibleAddingPath === false

    // variables from main page
    property var standardScreenHeight
    property var amountExtPartitions

    // own variables
    property string editOrNewPath : "new"
    property real standardPaddingLeft : Theme.paddingLarge + Theme.paddingSmall
    property bool visibleAddingPath : false
    property int tempStorageIndex : 0
    property string tempFolderpath : ""

    Component.onCompleted: {
        reloadDBSettings = false //for watchdog, reloading on firstPage after settings change
        clearDBoldEntries = false

        var folders2scanHOME = (storageItem.getSetting("infoFolders2scanHOME", "/Downloads|||/Pictures|||/Documents|||/android_storage")).split("|||")
        for (var i = 0; i < folders2scanHOME.length; i++) {
            if (folders2scanHOME[i] !== "") {
                idListModelScanFolders.append({ "folderPath" : folders2scanHOME[i], "storageMedia" : "$HOME" })
            }
        }
        if (amountExtPartitions !== 0) {
            var folders2scanEXTERN = (storageItem.getSetting("infoFolders2scanEXTERN", "/Download|||/DCIM|||/Android")).split("|||")
            var sdCards2scanEXTERN = (storageItem.getSetting("sdCards2scanEXTERN", "1|||1|||1")).split("|||")
        }
        else {
            folders2scanEXTERN = ""
            sdCards2scanEXTERN = "1"
        }
        for (var j = 0; j < folders2scanEXTERN.length; j++) {
            if (sdCards2scanEXTERN[j] !== "") {
                idListModelScanFolders.append({ "folderPath" : folders2scanEXTERN[j], "storageMedia" : sdCards2scanEXTERN[j] })
            }
        }
    }
    onDone: {
        if (result == DialogResult.Accepted) {
            var folderListHOME = ""
            var folderListEXTERN = ""
            var sdCardListExtern = ""
            for (var i = 0; i < idListModelScanFolders.count; i++) {
                if ((idListModelScanFolders.get(i).storageMedia).toString() === "$HOME") {
                    folderListHOME += "|||" + (idListModelScanFolders.get(i).folderPath).toString()
                }
                else { //"any number means it is an SD-CARD"
                    folderListEXTERN += "|||" + (idListModelScanFolders.get(i).folderPath).toString()
                    sdCardListExtern += "|||" + (idListModelScanFolders.get(i).storageMedia).toString()
                }
            }
            while (folderListHOME[0] === "|") { folderListHOME = folderListHOME.slice(1) }
            while (folderListEXTERN[0] === "|") { folderListEXTERN = folderListEXTERN.slice(1) }
            while (sdCardListExtern[0] === "|") { sdCardListExtern = sdCardListExtern.slice(1) }
            storageItem.setSetting( "infoFolders2scanHOME", folderListHOME )
            storageItem.setSetting( "infoFolders2scanEXTERN", folderListEXTERN )
            storageItem.setSetting( "sdCards2scanEXTERN", sdCardListExtern )
            storageItem.setSetting( "infoTimeLineDirectionIndex", idComboBoxFlowDirection.currentIndex )
            storageItem.setSetting("infoTimeShowDetailsIndex", idComboboxShowFileDetails.currentIndex)
            storageItem.setSetting("infoTimeCreationModification", idComboboxModificationCreationDate.currentIndex)
            storageItem.setSetting("infoTimeHiddenFiles", idComboboxHiddenFiles.currentIndex)
            storageItem.setSetting("infoTimeUseExifAlbum", idComboboxUseExifAlbum.currentIndex)
            storageItem.setSetting("infoActivateCoverImages", idComboboxActivateCoverImages.currentIndex)

            if (idComboBoxPreviewSize.currentIndex === 0) { var devideWidthBy = 4 }
            else if (idComboBoxPreviewSize.currentIndex === 2) { devideWidthBy = 2 }
            else { devideWidthBy = 3 } // currentIndex=1
            storageItem.setSetting("infoWidthDevider", devideWidthBy)

            if ( idComboboxSlideshowInterval.currentIndex === 0 ) { var tempCoverImageInterval = 2000 }
            else if ( idComboboxSlideshowInterval.currentIndex === 2 ) { tempCoverImageInterval = 10000 }
            else if ( idComboboxSlideshowInterval.currentIndex === 3 ) { tempCoverImageInterval = 30000 }
            else if ( idComboboxSlideshowInterval.currentIndex === 4 ) { tempCoverImageInterval = 60000 }
            else { tempCoverImageInterval = 5000 }// currentIndex=1, standard
            storageItem.setSetting("coverImageChangeInterval", tempCoverImageInterval)

            reloadDBSettings = true // variable declared in harbour-timeline.qml -> watchdog in FirstPage.qml checks for change and triggers update
        }
        else { // onRejected
            settingsRequireRescanImages = false
        }
    }

    HapticsEffect {id: rumbleEffect
         attackIntensity: 1.0
         attackTime: 250
         intensity: 1.0
         duration: 100
         fadeTime: 250
         fadeIntensity: 0.0
     }
    ListModel {
        id: idListModelScanFolders
    }

    SilicaFlickable {
        id: idMainFlickable
        anchors.fill: parent
        contentHeight: idSettingsColumn.height

        Column {
            id: idSettingsColumn
            width: page.width

            DialogHeader {
                id: idDialogHeader
            }
            Row {
                width: parent.width

                Label {
                    id: idLabelSettingsHeader
                    width: parent.width / 5 * 4
                    leftPadding: standardPaddingLeft
                    font.pixelSize: Theme.fontSizeExtraLarge
                    color: Theme.highlightColor
                    text: qsTr("Settings")
                }
                IconButton {
                    width: parent.width / 5
                    height: parent.height
                    anchors.verticalCenter: idLabelSettingsHeader.verticalCenter
                    icon.color: Theme.highlightColor
                    icon.scale: 1.1
                    icon.source: "image://theme/icon-m-about?"
                    onClicked: {
                        pageStack.animatorPush(Qt.resolvedUrl("AboutPage.qml"), {})
                    }
                }
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            ComboBox {
                id: idComboBoxPreviewSize
                function getCurrentIndex() {
                    var devideWidthBy = parseInt(storageItem.getSetting("infoWidthDevider", 3))
                    if (devideWidthBy === 4) {
                        return 0 // small
                    }
                    else if (devideWidthBy === 2) {
                        return 2 // large
                    }
                    else { // devide page.width by 3
                        return 1 // medium
                    }
                }
                width: parent.width
                label: qsTr("Preview Size: ")
                currentIndex: getCurrentIndex()
                description: qsTr("images in row")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("small")
                    }
                    MenuItem {
                        text: qsTr("medium")
                    }
                    MenuItem {
                        text: qsTr("large")
                    }
                }
            }
            ComboBox {
                id: idComboboxShowFileDetails
                width: parent.width
                label: qsTr("File info: ")
                currentIndex: (parseInt(storageItem.getSetting("infoTimeShowDetailsIndex", 0)) === 0) ? 0 : 1
                description: qsTr("timeline details")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("name only")
                    }
                    MenuItem {
                        text: qsTr("full path")
                    }
                }
            }
            ComboBox {
                id: idComboBoxFlowDirection
                width: parent.width
                label: qsTr("Sort lists: ")
                currentIndex: (parseInt(storageItem.getSetting("infoTimeLineDirectionIndex", 0)) === 0) ? 0 : 1
                description: qsTr("flow direction")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("new first")
                    }
                    MenuItem {
                        text: qsTr("old first")
                    }
                }

                property bool thisItemManuallyEntered : false
                onClicked: {
                    thisItemManuallyEntered = true
                }
                onCurrentIndexChanged: {
                    if (thisItemManuallyEntered) {
                        settingsRequireRescanImages = true
                    }
                }
            }
            ComboBox {
                id: idComboboxHiddenFiles
                width: parent.width
                label: qsTr("Hidden files + folders: ")
                currentIndex: (parseInt(storageItem.getSetting("infoTimeHiddenFiles", 0)) === 0) ? 0 : 1
                description: qsTr("file system")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("exclude")
                    }
                    MenuItem {
                        text: qsTr("show")
                    }
                }

                property bool thisItemManuallyEntered : false
                onClicked: {
                    thisItemManuallyEntered = true
                }
                onCurrentIndexChanged: {
                    if (thisItemManuallyEntered) {
                        settingsRequireRescanImages = true
                    }
                }
            }
            ComboBox {
                id: idComboboxModificationCreationDate
                width: parent.width
                label: qsTr("Use date: ")
                currentIndex: parseInt(storageItem.getSetting("infoTimeCreationModification", 0))
                description: (currentIndex !== 2) ? (qsTr("file system")) : (qsTr("where possible, otherwise uses creation date"))
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("first created")
                    }
                    MenuItem {
                        text: qsTr("last modified")
                    }
                    MenuItem {
                        text: qsTr("parse filename")
                    }
                }

                property bool thisItemManuallyEntered : false
                onClicked: {
                    thisItemManuallyEntered = true
                }
                onCurrentIndexChanged: {
                    if (thisItemManuallyEntered) {
                        settingsRequireRescanImages = true
                    }
                }
            }
            ComboBox {
                id: idComboboxUseExifAlbum
                width: parent.width
                label: qsTr("Set Album + Date by: ")
                currentIndex: (parseInt(storageItem.getSetting("infoTimeUseExifAlbum", 0)) === 0) ? 0 : 1
                description: qsTr("DateTime and IPTC keywords in JPG files")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("system")
                    }
                    MenuItem {
                        text: qsTr("metadata")
                    }
                }

                property bool thisItemManuallyEntered : false
                onClicked: {
                    thisItemManuallyEntered = true
                }
                onCurrentIndexChanged: {
                    if (thisItemManuallyEntered) {
                        settingsRequireRescanImages = true
                    }
                }
            }
            ComboBox {
                id: idComboboxActivateCoverImages
                width: parent.width
                label: qsTr("Album and Cover Art: ")
                currentIndex: (parseInt(storageItem.getSetting("infoActivateCoverImages", 0)) === 0) ? 0 : 1
                description: qsTr("show random images")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("off")
                    }
                    MenuItem {
                        text: qsTr("on")
                    }
                }
            }
            ComboBox {
                id: idComboboxSlideshowInterval
                function getCurrentIndex() {
                    var tempCoverImageInterval = parseInt(storageItem.getSetting("coverImageChangeInterval", 5000))
                    if (tempCoverImageInterval === 2000) {
                        return 0
                    }
                    else if (tempCoverImageInterval === 10000) {
                        return 2
                    }
                    else if (tempCoverImageInterval === 30000) {
                        return 3
                    }
                    else if (tempCoverImageInterval === 60000) {
                        return 4
                    }
                    else {
                        return 1 // standard === 5000
                    }
                }
                width: parent.width
                label: qsTr("Transition Interval: ")
                currentIndex: getCurrentIndex()
                description: qsTr("for album, cover and slideshow")
                menu: ContextMenu {
                    MenuItem {
                        text: qsTr("2 sec")
                    }
                    MenuItem {
                        text: qsTr("5 sec")
                    }
                    MenuItem {
                        text: qsTr("10 sec")
                    }
                    MenuItem {
                        text: qsTr("30 sec")
                    }
                    MenuItem {
                        text: qsTr("1 min")
                    }
                }
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Row {
                width: parent.width

                Column {
                    width: parent.width / 5 * 4

                    Label {
                        width: parent.width
                        leftPadding: standardPaddingLeft
                        verticalAlignment: Text.AlignVCenter
                        text: qsTr("Scan Folders:")
                    }
                    Label {
                        width: parent.width
                        leftPadding: standardPaddingLeft
                        font.pixelSize : Theme.fontSizeExtraSmallBase
                        color: Theme.secondaryColor
                        text: qsTr("including subfolders")
                    }
                }
                IconButton {
                    width: parent.width / 5
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    icon.color: Theme.highlightColor
                    icon.scale: 1.2
                    icon.source: (idTextFieldFolderRow.visible === false) ? ("image://theme/icon-m-add?") : ("image://theme/icon-m-remove?")
                    onClicked: {
                        (visibleAddingPath === true) ? (visibleAddingPath = false) : (visibleAddingPath = true)
                        editOrNewPath = "new"
                        settingsRequireRescanImages = true
                    }
                }
            }
            Item {
                id: idLastSpacerBeforeList
                width: parent.width
                height: Theme.paddingLarge
            }
            Repeater {
                width: parent.width
                model: idListModelScanFolders

                ListItem {
                    contentHeight: Math.max( Theme.itemSizeExtraSmall * 0.75, idLabelPath.height )
                    menu: ContextMenu {
                        id: idTestContextMenu

                        MenuItem {
                            text: qsTr("Edit")
                            onClicked: {
                                settingsRequireRescanImages = true
                                visibleAddingPath = false
                                editOrNewPath = index.toString()
                                tempFolderpath = folderPath.substring(1)
                                if (storageMedia.toString() === "$HOME") {
                                    tempStorageIndex = 0
                                }
                                else {
                                    tempStorageIndex = parseInt(storageMedia)
                                }
                                visibleAddingPath = true
                            }
                        }
                        MenuItem {
                            text: qsTr("Remove")
                            onClicked: {
                                settingsRequireRescanImages = true
                                remove()
                            }
                        }
                    }
                    onClicked: {
                        settingsRequireRescanImages = true
                    }

                    function remove() {
                        remorseDelete(function() {
                            idListModelScanFolders.remove(index)
                        })
                    }

                    Label {
                        id: idLabelPath
                        width: parent.width
                        leftPadding: standardPaddingLeft
                        rightPadding: leftPadding
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        color: Theme.secondaryHighlightColor
                        text: (storageMedia === "$HOME") ? ("+ " + storageMedia + folderPath) : ("+ " + "$CARD" + storageMedia + folderPath)
                    }
                }
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
            Row {
                id: idTextFieldFolderRow
                visible: visibleAddingPath === true
                width: parent.width
                onVisibleChanged: {
                    if (visible === true) {
                        idTextFieldFolder.focus = true
                        idTextFieldFolder.forceActiveFocus()
                        if (editOrNewPath === "new") {
                            idTextFieldFolder.text = ""
                            idComboboxStorageMedia.currentIndex = 0
                        }
                        else {
                            idTextFieldFolder.text = tempFolderpath
                            idComboboxStorageMedia.currentIndex = tempStorageIndex
                        }
                    }
                    else {
                        idTextFieldFolder.text = ""
                        idTextFieldFolder.focus = false
                    }
                }

                ComboBox {
                    id: idComboboxStorageMedia
                    width: parent.width / 3
                    anchors.top: parent.top
                    anchors.topMargin: -Theme.paddingSmall
                    onClicked: {
                        idTextFieldFolder.focus = false
                    }
                    onCurrentIndexChanged: {
                        idTextFieldFolder.focus = true
                    }
                    description: qsTr("volume")
                    menu: ContextMenu {
                        MenuItem {
                            text: "$HOME/"
                        }
                        Repeater {
                            id: idExtCardMenuItem
                            model: amountExtPartitions

                            MenuItem {
                                text: "$CARD" + (index+1) + "/"
                            }
                        }
                    }
                }
                TextField {
                    id: idTextFieldFolder
                    width: parent.width / 3 * 2
                    textLeftMargin: -Theme.paddingLarge * 2.5
                    placeholderText: qsTr("enter path to folder")
                    placeholderColor: Theme.secondaryColor
                    color: Theme.highlightColor
                    inputMethodHints: Qt.ImhNoPredictiveText
                    //validator: RegExpValidator { regExp: /[a-zA-Z0-9äöüÄÖÜ_=()\/.!?#+- ]*$/ }
                    onClicked: {
                        idComboboxStorageMedia.focus = false
                        settingsRequireRescanImages = true
                    }
                    EnterKey.onClicked: {
                        if (idComboboxStorageMedia.currentIndex === 0) {
                            var storageMedia = "$HOME"
                        }
                        else { // when it is an edited entry
                            storageMedia = (idComboboxStorageMedia.currentIndex).toString()
                        }

                        if (editOrNewPath != "new") {
                            idListModelScanFolders.set(parseInt(editOrNewPath), { "folderPath" : "/" + idTextFieldFolder.text, "storageMedia" : storageMedia })

                        }
                        else {
                            idListModelScanFolders.append({ "folderPath" : "/" + idTextFieldFolder.text, "storageMedia" : storageMedia })
                        }
                        visibleAddingPath = false
                    }
                }
            }
            Item {
                width: parent.width
                height: Theme.itemSizeMedium
            }
        }
    }
}
