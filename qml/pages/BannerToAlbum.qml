import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupAlbums
    z: 10
    width: parent.width
    height: parent.height
    visible: opacity > 0
    opacity: 0.0
    onClicked: {
        hide()
    }

    // UI variables
    property var targetAlbumPathList : []
    property string triggeredFrom : ""
    property string triggeredOn: ""

    Behavior on opacity {
        FadeAnimator {}
    }
    Rectangle {
        id: mainBackgroundRect
        anchors.fill: parent
        color: hideBackColor

        Rectangle {
            id: idBackgroundRect
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            width: parent.width - 2*Theme.paddingMedium
            height: parent.height - anchors.topMargin - Theme.paddingLarge - Theme.paddingSmall
            radius: Theme.paddingLarge
            border.width: 2
            border.color: Theme.highlightColor

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: idColumnAlbumBanner.height
                clip: true

                Column {
                    id: idColumnAlbumBanner
                    width: parent.width

                    Item {
                        width: parent.width
                        height: Theme.paddingLarge
                    }
                    IconButton {
                        width: parent.width
                        //height: Theme.iconSizeSmall
                        icon.source: (idTextFieldNewAlbum.visible === false) ? ("image://theme/icon-m-add?") : ("image://theme/icon-m-remove?")
                        onClicked: {
                            (idTextFieldNewAlbum.visible === false) ? (idTextFieldNewAlbum.visible = true) : (idTextFieldNewAlbum.visible = false)
                            if (idTextFieldNewAlbum.visible === true) {
                                idTextFieldNewAlbum.text = ""
                                idTextFieldNewAlbum.focus = true
                                idTextFieldNewAlbum.forceActiveFocus()
                            }
                            else {
                                idTextFieldNewAlbum.focus = false
                            }
                        }
                    }
                    Item {
                        width: parent.width
                        height: Theme.paddingLarge
                    }

                    // create a new album
                    TextField {
                        id: idTextFieldNewAlbum
                        visible: false
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        color: Theme.highlightColor
                        inputMethodHints: Qt.ImhNoPredictiveText
                        //validator: RegExpValidator { regExp: /[a-zA-Z0-9äöüÄÖÜ_=()\/.!?#+-]*$/ }
                        placeholderText: qsTr("new album")
                        EnterKey.onClicked: {
                            if (text.length > 0) {
                                idListModelAlbums.append({"album_name" : text })
                                for (var j = 0; j < targetAlbumPathList.length; j++) {
                                    setModelImagesAndDB( j, targetAlbumPathList[j], text )
                                }
                                text = ""
                                hide()
                            }
                        }
                        onTextChanged: {
                            if (acceptableInput) {
                                if (text === standardAlbum || text === standardSearchAlbum) {
                                    text = qsTr("new") + text
                                }
                            }
                        }
                    }

                    // existing albums
                    ListView {
                        id: idListViewBooksLongname
                        width: parent.width
                        height: contentHeight

                        model: idListModelAlbums
                        delegate: ListItem {
                            visible: ( album_name !== standardSearchAlbum && album_name !== standardFavouritesAlbum )
                            enabled: visible
                            contentX: idBackgroundRect.radius
                            contentWidth: parent.width - 2* contentX
                            contentHeight: ( album_name !== standardSearchAlbum && album_name !== standardFavouritesAlbum ) ? Theme.itemSizeExtraSmall : 0
                            onClicked: {
                                for (var j = 0; j < targetAlbumPathList.length; j++) {
                                    setModelImagesAndDB( j, targetAlbumPathList[j], album_name )
                                }
                                hide()
                            }
                            Label {
                                text: (album_name[0] === ".")
                                      ? (album_name.substring(1))
                                      : (album_name)
                                color: Theme.primaryColor
                                font.bold: (album_name[0] === ".")
                                font.pixelSize: Theme.fontSizeSmall
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }

        }
    }


    function notify( color, upperMargin, chosenFilesArray, detailTrigger, triggerPage ) {
        triggeredFrom = detailTrigger
        triggeredOn = triggerPage
        if (color && (typeof(color) != "undefined")) { idBackgroundRect.color = color }
        else { idBackgroundRect.color = Theme.rgba(Theme.highlightDimmerColor, 1) }
        if (upperMargin && (typeof(upperMargin) != "undefined")) { idBackgroundRect.anchors.topMargin = upperMargin }
        else { idBackgroundRect.height = page.height / 2 }
        targetAlbumPathList = chosenFilesArray
        idFooterRow.visible = false
        popupAlbums.opacity = 1.0
    }

    function hide() {
        idTextFieldNewAlbum.focus = false
        idTextFieldNewAlbum.visible = false
        idFooterRow.visible = true
        countDistinctAlbums( "standard" )
        popupAlbums.opacity = 0.0
        if (triggeredOn !== "triggeredOnFirstPage") {
            unselectAll()
        }
    }

    function setModelImagesAndDB( targetIndex, targetImagePathListArray, targetAlbumName ) { // ToDo: this takes way too long for larger amount of images
        var targetIndex_FolderOrAlbum = targetImagePathListArray[0]
        var targetImagePath = targetImagePathListArray[1]
        var targetImage_listModelImages_baseIndex = targetImagePathListArray[2]

        // save info to IPTC tag if available and wanted
        if (settingUseExif !== 0) {
            if ( targetAlbumName !== standardAlbum) {
                py.insertMetadataKeywords ( targetAlbumName, targetImagePath )
            }
            else {
                py.removeMetadataKeywords ( targetImagePath )
            }
        }

        // update DB info
        if (targetAlbumName !== standardAlbum) {
            storageItem.addAlbum(targetImagePath, targetAlbumName)
        }
        else {
            storageItem.removeAlbum(targetImagePath)
        }

        // update lists
        if (triggeredFrom === "fromTimeline" || triggeredFrom === "fromFolder") { // uses index of main list only

            // update album in main list
            idListModelImages.setProperty(targetImage_listModelImages_baseIndex, "album", targetAlbumName)

            // update album when called from inside a folder list (multi-selected images only)
            if (triggeredFrom === "fromFolder") {
                idListModelImagesFolder.setProperty(targetIndex_FolderOrAlbum, "album", targetAlbumName)
            }
        }

        else if (triggeredFrom === "fromAlbum") { // treats index as the index from albumList
            for (var j = 0; j < idListModelImages.count; j++) {
                if (idListModelImages.get(j).filePath === targetImagePath) {
                    idListModelImages.setProperty(j, "album", targetAlbumName)
                }
            }
            for (var l=idListModelImagesAlbum.count -1 ; l >= 0; --l) {
                if ( (idListModelImagesAlbum.get(l).filePath).toString() === (targetImagePath).toString() ) {
                    if ( (idListModelImagesAlbum.get(l).album).toString() !== (targetAlbumName).toString() ) {
                        if ( currentAlbum !== standardFavouritesAlbum && currentAlbum !== standardSearchAlbum ) {
                            idListModelImagesAlbum.remove(l)
                        }
                    }
                }
            }

            if (idListModelImagesAlbum.count < 1) {
                for (var k = idListModelAlbums.count -1; k >= 0; --k) {
                    if ((idListModelAlbums.get(k).album_name === currentAlbum)) {
                        idListModelAlbums.remove(k)
                    }
                }
                pageStack.pop()
            }
        }
    }

}
