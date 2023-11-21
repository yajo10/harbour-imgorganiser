import QtQuick 2.6
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import Nemo.Thumbnailer 1.0
import Sailfish.Share 1.0


Page {
    id: idAlbumPage
    allowedOrientations: Orientation.Portrait //All
    Component.onDestruction: {
        multiSelectActive === false
        unselectAll()
    }

    property var showSearchText
    property var currentModel
    property int counterSelectedTotal : 0

    BannerToAlbum {
        id: bannerToAlbumFromAlbum
    }
    RemorsePopup {
        height: Theme.itemSizeLarge * 1.3
        id: remorseAlbum
    }
    BannerResize {
        id: bannerResizeFromAlbum
    }

    SilicaGridView {
        id: idGridViewAlbums
        anchors.fill: parent
        clip: true
        cellWidth: minimumTimelineListItemHeight
        cellHeight: cellWidth
        header: Row {
            width: parent.width

            Item {
                width: Theme.itemSizeSmall
                height: upperFreeHeight
            }
            Label {
                function getTitle() {
                    if (currentModel === "albums") {
                        if (currentAlbum !== standardSearchAlbum) {
                            var returnText = currentAlbum
                            if (returnText[0] === ".") {
                                returnText = returnText.substring(1)
                            }
                        }
                        else {
                            returnText = currentAlbum + "<br>" + "<i>"+showSearchText+"</i>"
                            if (returnText[0] === ".") {
                                returnText = returnText.substring(1)
                            }
                        }
                    }
                    else { // currentModel === "folders"
                        returnText = currentFolder
                    }
                    // get rid of first "." character
                    return returnText
                }
                width: (currentModel === "albums") ? (parent.width - Theme.itemSizeSmall * 2) : (parent.width - Theme.itemSizeSmall - Theme.paddingLarge)
                height: (implicitHeight >= upperFreeHeight/3*2) ? (implicitHeight + upperFreeHeight/2) : upperFreeHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: (currentModel === "albums") ? Text.AlignHCenter : Text.AlignRight
                wrapMode: Text.WordWrap
                truncationMode: (currentModel === "albums") ? TruncationMode.Elide : TruncationMode.None
                textFormat: Text.StyledText
                font.pixelSize: (currentModel === "albums") ? Theme.fontSizeMedium : Theme.fontSizeTiny
                text: getTitle()
            }
        }

        PullDownMenu {
            quickSelect: true
            highlightColor: (multiSelectActive === false) ? Theme.highlightBackgroundColor : Theme.errorColor
            backgroundColor: (multiSelectActive === false) ? Theme.highlightBackgroundColor : Theme.errorColor
            MenuItem {
                text: (multiSelectActive === true) ? qsTr("Unselect") : qsTr("Selection")
                onClicked: {
                    if (multiSelectActive === true) {
                        multiSelectActive = false
                        unselectAll()
                    }
                    else {
                        multiSelectActive = true
                    }
                }
            }
        }
        VerticalScrollDecorator {}

        model: (currentModel === "albums") ? idListModelImagesAlbum : idListModelImagesFolder
        delegate: GridItem {
            id: idGridItemViewAlbums
            contentWidth: minimumTimelineListItemHeight - Theme.paddingSmall
            contentHeight: contentWidth
            contentX: Theme.paddingSmall / 2
            onClicked: {
                // normal mode
                if (multiSelectActive === false) {
                    var currentImageIndex = index
                    var allCurrentModelImagePathsArray = []
                    if (currentModel === "albums") {
                        for (var j = 0; j < idListModelImagesAlbum.count; j++) {
                            allCurrentModelImagePathsArray.push(idListModelImagesAlbum.get(j).filePath)
                        }
                    } // "folders"
                    else {
                        for (j = 0; j < idListModelImagesFolder.count; j++) {
                            allCurrentModelImagePathsArray.push(idListModelImagesFolder.get(j).filePath)
                        }
                    }
                    pageStack.animatorPush(viewPage, {
                                               upperFreeHeight : upperFreeHeight,
                                               allCurrentModelImagePathsArray : allCurrentModelImagePathsArray,
                                               currentImageIndex : currentImageIndex,
                                           })
                }
                // when multiselection is active
                else {
                    if (selected) {
                        selected = false
                        counterSelectedTotal = counterSelectedTotal - 1
                    }
                    else {
                        selected = true
                        counterSelectedTotal = counterSelectedTotal + 1
                    }
                }
            }

            function removeFile( filePathArray ) {
                remorseAlbum.execute( qsTr("Delete File?"), function() {
                    if (currentModel === "albums") {
                        deleteThisImage( filePathArray, "albumPage" )
                    }
                    else { // "folders"
                        deleteThisImage( filePathArray, "folderPage" )
                    }
                    multiSelectActive = false
                    unselectAll()
                })
            }

            menu: Component {
                ContextMenu {
                    hasContent: (multiSelectActive !== true) || (multiSelectActive === true && counterSelectedTotal !== 0)
                    MenuItem {
                        text: qsTr("Set Album")
                        onClicked: {
                            var chosenFilesArray = []

                            // multi-select active
                            if (multiSelectActive === true) {

                                // albums
                                if (currentModel === "albums") {

                                    // for all albums: normal + favorites + search
                                    for (var j = 0; j < idListModelImagesAlbum.count; j++) {
                                        if (idListModelImagesAlbum.get(j).selected === true) {
                                            var targetIndex_FolderOrAlbum = j
                                            chosenFilesArray.push( [targetIndex_FolderOrAlbum, idListModelImagesAlbum.get(j).filePath, idListModelImagesAlbum.get(j).listModelImages_baseIndex] )
                                            idListModelImagesAlbum.setProperty(j, "selected", false)
                                        }
                                    }

                                    // additionally update search list ???
                                    if (currentAlbum === standardSearchAlbum) {
                                        for ( j = 0; j < idListModelSearch.count; j++) {
                                            if (idListModelSearch.get(j).selected === true) {
                                                idListModelSearch.setProperty(j, "selected", false)
                                            }
                                        }
                                    }

                                    // additionally update favorites list ???
                                    else if (currentAlbum === standardFavouritesAlbum) {
                                        for (j = 0; j < idListModelFavourites.count; j++) {
                                            if (idListModelFavourites.get(j).selected === true) { // why not working?
                                                idListModelFavourites.setProperty(j, "selected", false)
                                            }
                                        }
                                    }
                                }

                                // folders
                                else {
                                    for (j = 0; j < idListModelImagesFolder.count; j++) {
                                        if (idListModelImagesFolder.get(j).selected === true) {
                                            targetIndex_FolderOrAlbum = j
                                            chosenFilesArray.push( [targetIndex_FolderOrAlbum, idListModelImagesFolder.get(j).filePath, idListModelImagesFolder.get(j).listModelImages_baseIndex] )
                                            idListModelImagesFolder.setProperty(j, "selected", false)
                                        }
                                    }
                                }
                            }

                            // single select active
                            else {
                                targetIndex_FolderOrAlbum = index
                                chosenFilesArray.push( [targetIndex_FolderOrAlbum, filePath, listModelImages_baseIndex] )
                             }

                            // use different caller methods for albums or folders
                            if (currentModel === "albums") {
                                bannerToAlbumFromAlbum.notify( Theme.highlightDimmerColor, Theme.itemSizeHuge, chosenFilesArray, "fromAlbum", "triggeredOnAlbumPage" )
                            }
                            else { // "folders"
                                bannerToAlbumFromAlbum.notify( Theme.highlightDimmerColor, Theme.itemSizeHuge, chosenFilesArray, "fromFolder", "triggeredOnAlbumPage" )
                            }
                            multiSelectActive = false
                        }
                    }
                    MenuItem {
                        text: (isFavourite !== "true") ? qsTr("Set Favourite") : qsTr("From Favourite")
                        onClicked: {
                            // only use isFavourite info from the item currently touched
                            if (isFavourite !== "true") { // add to favourites
                                var updateType = "addFavourite"
                            }
                            else { // remove from favourites
                                updateType = "removeFavourite"
                            }

                            var chosenFilesArray = []
                            if (multiSelectActive === true) {
                                if (currentModel === "albums") {
                                    for (var j = 0; j < idListModelImagesAlbum.count; j++) {
                                        if (idListModelImagesAlbum.get(j).selected === true) {
                                            chosenFilesArray.push(idListModelImagesAlbum.get(j).filePath)

                                            //First check if entry already exists in favourites list!!!
                                            var entryAlreadyThere = false
                                            for (var k = 0; k < idListModelFavourites.count; k++) {
                                                if (idListModelFavourites.get(k).filePath === idListModelImagesAlbum.get(j).filePath) {
                                                    entryAlreadyThere = true
                                                }
                                            }

                                            // add items to list when not yet existing
                                            if (entryAlreadyThere === false) {
                                                if (updateType === "addFavourite") {
                                                    idListModelFavourites.append({
                                                                     "creationDateMS" : idListModelImagesAlbum.get(j).creationDateMS,
                                                                     "filePath" : idListModelImagesAlbum.get(j).filePath,
                                                                     "monthYear" : idListModelImagesAlbum.get(j).monthYear,
                                                                     "day" : idListModelImagesAlbum.get(j).day,
                                                                     "folderPath" : idListModelImagesAlbum.get(j).folderPath,
                                                                     "fileName" : idListModelImagesAlbum.get(j).fileName,
                                                                     "estimatedSize" : idListModelImagesAlbum.get(j).estimatedSize,
                                                                     "album" : idListModelImagesAlbum.get(j).album,
                                                                     "selected" : false,
                                                                     "exifInfo" : idListModelImagesAlbum.get(j).album,
                                                                     "isSearchResult" : false,
                                                                     "timestampSource" : idListModelImagesAlbum.get(j).timestampSource,
                                                                     "isFavourite" : "true",
                                                                     "listModelImages_baseIndex" : idListModelImagesAlbum.get(j).listModelImages_baseIndex
                                                                 })
                                                }
                                            }
                                        }
                                    }
                                }
                                else { // "folders"
                                    for (j = 0; j < idListModelImagesFolder.count; j++) {
                                        if (idListModelImagesFolder.get(j).selected === true) {
                                            chosenFilesArray.push(idListModelImagesFolder.get(j).filePath)

                                            //First check if entry already exists in favourites list!!!
                                            entryAlreadyThere = false
                                            for (k = 0; k < idListModelFavourites.count; k++) {
                                                if (idListModelFavourites.get(k).filePath === idListModelImagesFolder.get(j).filePath) {
                                                    entryAlreadyThere = true
                                                }
                                            }

                                            // add items to list when not yet existing
                                            if (entryAlreadyThere === false) {

                                                if (updateType === "addFavourite") {
                                                    idListModelFavourites.append({
                                                                     "creationDateMS" : idListModelImagesFolder.get(j).creationDateMS,
                                                                     "filePath" : idListModelImagesFolder.get(j).filePath,
                                                                     "monthYear" : idListModelImagesFolder.get(j).monthYear,
                                                                     "day" : idListModelImagesFolder.get(j).day,
                                                                     "folderPath" : idListModelImagesFolder.get(j).folderPath,
                                                                     "fileName" : idListModelImagesFolder.get(j).fileName,
                                                                     "estimatedSize" : idListModelImagesFolder.get(j).estimatedSize,
                                                                     "album" : idListModelImagesFolder.get(j).album,
                                                                     "selected" : false,
                                                                     "exifInfo" : idListModelImagesFolder.get(j).album,
                                                                     "isSearchResult" : false,
                                                                     "timestampSource" : idListModelImagesFolder.get(j).timestampSource,
                                                                     "isFavourite" : "true",
                                                                     "listModelImages_baseIndex" : idListModelImagesFolder.get(j).listModelImages_baseIndex
                                                                 })
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // single image selected
                            else {
                                chosenFilesArray.push(filePath)
                                if (updateType === "addFavourite") {
                                    idListModelFavourites.append({
                                                     "creationDateMS" : creationDateMS,
                                                     "filePath" : filePath,
                                                     "monthYear" : monthYear,
                                                     "day" : day,
                                                     "folderPath" : folderPath,
                                                     "fileName" : fileName,
                                                     "estimatedSize" : estimatedSize,
                                                     "album" : album,
                                                     "selected" : false,
                                                     "exifInfo" :  album,
                                                     "isSearchResult" : false,
                                                     "timestampSource" : timestampSource,
                                                     "isFavourite" : "true",
                                                     "listModelImages_baseIndex" : listModelImages_baseIndex
                                                 })
                                }
                            }

                            // delete from currentAlbumModel only if it is called from inside favourites album
                            if ( currentAlbum !== standardFavouritesAlbum ) {
                                var calledFromPage = "fromAnyAlbumPage"
                            }
                            else {
                                calledFromPage = "fromFavouritesAlbum"
                            }
                            updateAllLists_isFavourite (calledFromPage, updateType, chosenFilesArray)
                            multiSelectActive = false
                            unselectAll()
                        }
                    }
                    MenuItem {
                        enabled: multiSelectActive === false
                        visible: enabled
                        text: qsTr("Open with")
                        onClicked: Qt.openUrlExternally(filePath)
                    }
                    MenuItem {
                        text: (multiSelectActive === false) ? qsTr("Share") : qsTr("Share as ZIP")
                        ShareAction {
                            id: shareAction
                            mimeType: "image/*"
                        }
                        onClicked: {
                            if (multiSelectActive === false) {
                                shareAction.resources = [filePath]
                                shareAction.trigger()
                            }
                            else {
                                getAllSelectedPaths( "createZip" )
                            }
                        }
                    }
                    MenuItem {
                        enabled: pillowAvailable && multiSelectActive
                        visible: enabled
                        text: qsTr("Resize")
                        onClicked: {
                            var chosenFilesArray = []
                            if (multiSelectActive === true) {
                                if (currentModel === "albums") {
                                    for (var j = 0; j < idListModelImagesAlbum.count; j++) {
                                        if (idListModelImagesAlbum.get(j).selected === true) {
                                            chosenFilesArray.push(idListModelImagesAlbum.get(j).filePath)
                                        }
                                    }
                                }
                                else { //"folders"
                                    for (j = 0; j < idListModelImagesFolder.count; j++) {
                                        if (idListModelImagesFolder.get(j).selected === true) {
                                            chosenFilesArray.push(idListModelImagesFolder.get(j).filePath)
                                            idListModelImagesFolder.setProperty(j, "selected", false)
                                        }
                                    }
                                }
                            }

                            // make a string from array
                            var imagePathsList = ""
                            for (var i = 0; i < chosenFilesArray.length; i++) {
                                imagePathsList = imagePathsList + chosenFilesArray[i] + "|||"
                            }
                            if (imagePathsList.slice(-3) === "|||") {
                                imagePathsList = imagePathsList.slice(0, -3)
                            }

                            // prepare standard sizes
                            var startWidth = 1920
                            var startHeight = 1920
                            bannerResizeFromAlbum.notify( startWidth, startHeight, imagePathsList )
                            multiSelectActive = false
                        }
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: {
                            var chosenFilesArray = []
                            if (multiSelectActive === true) {
                                if (currentModel === "albums") {
                                    for (var j = 0; j < idListModelImagesAlbum.count; j++) {
                                        if (idListModelImagesAlbum.get(j).selected === true) {
                                            chosenFilesArray.push(idListModelImagesAlbum.get(j).filePath)
                                        }
                                    }
                                }
                                else { // "folders"
                                    for (j = 0; j < idListModelImagesFolder.count; j++) {
                                        if (idListModelImagesFolder.get(j).selected === true) {
                                            chosenFilesArray.push(idListModelImagesFolder.get(j).filePath)
                                        }
                                    }
                                }
                            }
                            else {
                                chosenFilesArray.push(filePath)
                            }
                            removeFile( chosenFilesArray )
                        }
                    }
                    MenuItem {
                        enabled: multiSelectActive === false
                        visible: enabled
                        text: qsTr("Info")
                        onClicked: {
                            idImageSizeHelper.source = ""
                            idImageSizeHelper.source = filePath
                            var imageWidth = idImageSizeHelper.sourceSize.width
                            var imageHeight = idImageSizeHelper.sourceSize.height
                            py.getEXIFdata( filePath, creationDateMS, monthYear, day, folderPath, fileName, estimatedSize, album, imageWidth, imageHeight, timestampSource, isFavourite )
                        }
                    }
                }
            }

            Image {
                width: parent.width
                height: width
                sourceSize.width: width
                sourceSize.height: height
                autoTransform: true
                fillMode: Image.PreserveAspectCrop
                source: (reloadImage === false) ? "image://nemoThumbnail/" + filePath : ""
                asynchronous: true
                cache: false

                Rectangle {
                    id: idBackHighlight
                    visible: selected
                    anchors.fill: parent
                    color: Theme.highlightDimmerColor
                    opacity: 0.5
                }
                Icon {
                    visible: isFavourite === "true" && currentAlbum !== standardFavouritesAlbum
                    highlightColor: Theme.primaryColor
                    width: parent.width / 4.5
                    height: width
                    source: "image://theme/icon-m-favorite-selected?"

                    Rectangle {
                        z: -1
                        anchors.fill: parent
                        visible: idBackHighlight.visible === false
                        color: Theme.highlightDimmerColor
                        opacity: 0.75
                    }
                }
                Icon {
                    visible: selected
                    anchors.centerIn: parent
                    highlightColor: Theme.primaryColor
                    source: "image://theme/icon-l-acknowledge?"
                }
            }
            BusyIndicator {
                anchors.centerIn: parent
                running: finishedLoading === false
                size: BusyIndicatorSize.Medium
            }
        }
    }

    function getAllSelectedPaths ( intention ) {
        var imagePathsList = ""

        if (currentModel === "albums") { // ALBUM and SEARCH
            for (var i = 0; i < idListModelImagesAlbum.count; i++) {
                if ( (idListModelImagesAlbum.get(i).selected) === true ) {
                    imagePathsList = imagePathsList + (idListModelImagesAlbum.get(i).filePath).toString() + "|||"
                }
            }
        }
        else { // FOLDER
            for (i = 0; i < idListModelImagesFolder.count; i++) {
                if ( (idListModelImagesFolder.get(i).selected) === true ) {
                    imagePathsList = imagePathsList + (idListModelImagesFolder.get(i).filePath).toString() + "|||"
                }
            }
        }

        if (imagePathsList.slice(-3) === "|||") {
            imagePathsList = imagePathsList.slice(0, -3)
        }

        if (intention === "createZip") {
            py.packZipImagesTmp( imagePathsList )
        }

        unselectAll()
    }

    function unselectAll() {
        for (var i = 0; i < idListModelImages.count; i++) {
            idListModelImages.setProperty(i, "selected", false)
        }
        for ( i = 0; i < idListModelImagesAlbum.count; i++) {
            idListModelImagesAlbum.setProperty(i, "selected", false)
        }
        for ( i = 0; i < idListModelImagesFolder.count; i++) {
            idListModelImagesFolder.setProperty(i, "selected", false)
        }
        for ( i = 0; i < idListModelSearch.count; i++) {
            idListModelSearch.setProperty(i, "selected", false)
        }
        multiSelectActive = false
        counterSelectedTotal = 0
    }

}
