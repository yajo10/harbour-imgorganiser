import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupSearch
    z: 10
    width: parent.width
    height: parent.height
    opacity: 0.0
    visible: opacity > 0
    onClicked: {
        hide()
    }

    Behavior on opacity {
        FadeAnimator {}
    }
    Rectangle {
        id: mainBackgroundRect
        anchors.fill: parent
        color: hideBackColor

        Rectangle {
            id: idBackgroundRectSearch
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: upperFreeHeight
            width: parent.width - 2*Theme.paddingMedium
            height: Theme.itemSizeHuge
            radius: Theme.paddingLarge
            border.width: 2
            border.color: Theme.highlightColor

            SearchField {
                id: idInputSearchField
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                inputMethodHints: Qt.ImhNoPredictiveText
                //validator: RegExpValidator { regExp: /[a-zA-Z0-9äöüÄÖÜ_=()\/.!?#+-]*$/ }
                EnterKey.onClicked: {
                    tempSearchText = text
                    searchAllImages( text )
                    text = ""
                    focus = false
                    hide()
                }
            }
        }
    }


    function notify( color ) {
        idFooterRow.visible = false
        popupSearch.opacity = 1.0
        if (color && (typeof(color) != "undefined")) { idBackgroundRectSearch.color = color }
        else { idBackgroundRectSearch.color = Theme.rgba(Theme.highlightDimmerColor, 1) }
        idInputSearchField.focus = true
    }

    function hide() {
        idInputSearchField.focus = false
        idFooterRow.visible = true
        popupSearch.opacity = 0.0
    }

    function searchAllImages( text ) {
        idListModelSearch.clear()
        for (var j = 0; j < idListModelImages.count; j++) {
            var currentPath = idListModelImages.get(j).filePath
            if ( currentPath.toLowerCase().indexOf( (idInputSearchField.text).toLowerCase() ) !== -1 ) {
                //console.log(currentPath)
                idListModelSearch.append({
                    "creationDateMS" : idListModelImages.get(j).creationDateMS,
                    "filePath" : idListModelImages.get(j).filePath,
                    "monthYear" : idListModelImages.get(j).monthYear,
                    "day" : idListModelImages.get(j).day,
                    "folderPath" : idListModelImages.get(j).folderPath,
                    "fileName" : idListModelImages.get(j).fileName,
                    "estimatedSize" : idListModelImages.get(j).estimatedSize,
                    "album" : idListModelImages.get(j).album,
                    "selected" : false,
                    "exifInfo" :  idListModelImages.get(j).album,
                    "isSearchResult" : true,
                    "timestampSource" : idListModelImages.get(j).timestampSource,
                    "isFavourite" : idListModelImages.get(j).isFavourite
                })
            }
        }
        countDistinctAlbums( "fromSearch" )
    }

}
