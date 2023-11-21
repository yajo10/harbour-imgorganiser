import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupRename
    z: 10
    width: parent.width
    height: parent.height
    visible: opacity > 0
    opacity: 0.0
    onClicked: {
        hide()
    }

    // UI variables
    property string oldAlbumName : ""

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
            anchors.bottom: parent.bottom
            anchors.bottomMargin: upperFreeHeight
            width: parent.width - 2*Theme.paddingMedium
            height: Theme.itemSizeHuge
            radius: Theme.paddingLarge
            border.width: 2
            border.color: Theme.highlightColor

            TextField {
                id: idTextFieldRename
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
                text: oldAlbumName
                inputMethodHints: Qt.ImhNoPredictiveText
                //validator: RegExpValidator { regExp: /[a-zA-Z0-9äöüÄÖÜ_=()\/.!?#+-]*$/ }
                EnterKey.onClicked: {
                    if (text.length > 0) {
                        renameAlbum_DB( text )
                        focus = false
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
        }

    }


    function notify( color, albumName ) {
        if (color && (typeof(color) != "undefined")) { idBackgroundRect.color = color }
        else { idBackgroundRect.color = Theme.rgba(Theme.highlightDimmerColor, 1) }
        oldAlbumName = albumName

        idTextFieldRename.focus = true
        idFooterRow.visible = false
        popupRename.opacity = 1.0
    }

    function hide() {
        idTextFieldRename.focus = false
        idFooterRow.visible = true
        popupRename.opacity = 0.0
    }

    function renameAlbum_DB( text ) {
        if (oldAlbumName !== text) {

            var metadataActive = parseInt(storageItem.getSetting("infoTimeUseExifAlbum", 0))

            // rename album in distinct album list
            for (var h = 0; h < idListModelAlbums.count; h++) {
                if (idListModelAlbums.get(h).album_name === oldAlbumName) {
                    idListModelAlbums.setProperty(h, "album_name", text)
                }
            }
            // rename album-info in current image list
            for (var i = 0; i < idListModelImagesAlbum.count; i++) {
                if (idListModelImagesAlbum.get(i).album === oldAlbumName) {
                    idListModelImagesAlbum.setProperty(i, "album", text)
                }
            }

            // rename all images in main list and DB
            for (var j = 0; j < idListModelImages.count; j++) {
                if (idListModelImages.get(j).album === oldAlbumName) {
                    idListModelImages.setProperty(j, "album", text)
                    storageItem.addAlbum(idListModelImages.get(j).filePath, text)

                    // save info to IPTC tag if available and wanted
                     if (metadataActive !== 0) {
                        if ( text !== standardAlbum) {
                            py.insertMetadataKeywords ( text, idListModelImages.get(j).filePath )
                        }
                        else {
                            py.removeMetadataKeywords ( idListModelImages.get(j).filePath )
                        }
                    }
                }
            }

            // update favouritesModel as well
            if (idListModelFavourites.count > 0) {
                for ( var k = 0; k < idListModelFavourites.count; k++) {
                    if (idListModelFavourites.get(k).album === oldAlbumName) {
                        //console.log("found it in favourites: " + idListModelFavourites.get(k).filePath)
                        idListModelFavourites.setProperty(k, "album", text)
                    }
                }
            }

            // update searchModel as well
            if (idListModelSearch.count > 0) {
                for ( k = 0; k < idListModelSearch.count; k++) {
                    if (idListModelSearch.get(k).album === oldAlbumName) {
                        //console.log("found it in search: " + idListModelSearch.get(k).filePath)
                        idListModelSearch.setProperty(k, "album", text)
                    }
                }
            }

            if (idListModelSearch.count < 1) {
                countDistinctAlbums( "standard" )
            }
            else {
                countDistinctAlbums( "fromSearch" )
            }
        }
    }

}
