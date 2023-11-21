import QtQuick 2.6
import Sailfish.Silica 1.0
import io.thp.pyotherside 1.5
import Nemo.Thumbnailer 1.0
import QtFeedback 5.0 // haptic effects
import Sailfish.Share 1.0
import QtGraphicalEffects 1.0


Page {
    id: page
    allowedOrientations: Orientation.Portrait

    property int amountExtPartitions : 0
    property var distinctAlbums : []
    property string standardAlbum : "." + qsTr("UNSORTED")
    property string standardSearchAlbum : "." + qsTr("SEARCH")
    property string standardFavouritesAlbum : "." + qsTr("FAVOURITES")
    property var standardScreenWidth
    property var standardScreenHeight
    property string currentAlbum : ""
    property string currentFolder : ""
    property string tempSearchText : ""
    property real minimumFolderListItemHeight : standardScreenWidth / (infoWidthDevider+2) // (infoWidthDevider === 2) ? Theme.itemSizeExtraLarge : Theme.itemSizeMedium
    property var minimumTimelineListItemHeight // done in Component.onCompleted
    property bool fileBrowserInstalled : false
    property bool multiSelectActive : false
    property real upperFreeHeight : Theme.itemSizeLarge
    property color buttonBackgroundColor: Theme.rgba(Theme.highlightDimmerColor, 1)
    property var hideBackColor : Theme.rgba(Theme.overlayBackgroundColor, 0.9)
    property bool delegateMenuOpen : false
    property int imagesWorkload2Rescan : 75

    // image list generation and checks against db
    property int settingUseExif : 0 //parseInt(storageItem.getSetting("infoTimeUseExifAlbum", 0))
    property var dbFavouritesArray : [] //storageItem.getAllStoredKeywords( "noFilesAvailable" )
    property var dbPathAlbumsArray : [] //storageItem.getAllStoredImagesAlbums( "noPathAvailable", "noInfoAvailable" )

    // python image functions
    property bool pillowAvailable : true



    Component.onCompleted: {
        py.getAmountExtPartitions() // -> result will trigger py.scanForImages()
        py.checkCMDexistance("harbour-file-browser")
        standardScreenWidth = page.width
        standardScreenHeight = page.height
        minimumTimelineListItemHeight = standardScreenWidth / infoWidthDevider
    }

    Item {
        id: idWatchdog_reloadSettingsFromDB
        enabled: ( reloadDBSettings === true ) ? true : false
        onEnabledChanged: {
            if ( enabled === true ) { // on_enter
                finishedLoading = false
                settingUseExif = parseInt(storageItem.getSetting("infoTimeUseExifAlbum", 0))
                amountDetails = parseInt(storageItem.getSetting("infoTimeShowDetailsIndex", 0))
                infoWidthDevider = parseInt(storageItem.getSetting("infoWidthDevider", 3))
                infoActivateCoverImages = parseInt(storageItem.getSetting("infoActivateCoverImages", 0))
                coverImageChangeInterval = parseInt(storageItem.getSetting("coverImageChangeInterval", 5000))
                minimumTimelineListItemHeight = standardScreenWidth / infoWidthDevider
                //console.log("setting_rescan_status: " + settingsRequireRescanImages)
                if (settingsRequireRescanImages === true) {
                    clearAllLists()
                    idDelayTimerApplySettingsScan4Images.start()
                }
                settingsRequireRescanImages = false
                finishedLoading = true
            }
        }
    }
    Item {
        id: idWatchdog_clearDBoldEntries
        enabled: ( clearDBoldEntries === true ) ? true : false
        onEnabledChanged: {
            if ( enabled === true ) { // on_enter
                py.checkDB_fileExistance()
            }
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
    RemorsePopup {
        height: Theme.itemSizeLarge * 1.3
        id: remorse
    }
    Item {
        visible: false
        Image {
            visible: false
            id: idImageSizeHelper
            cache: false
            source: ""
        }
    }
    Component {
        id: datePickerComponent
        DatePickerDialog {}
    }
    Component {
        id: albumPage
        AlbumPage {}
    }
    Component {
        id: fileDetailPage
        FileDetailPage{}
    }
    Component {
        id: viewPage
        ViewPage {}
    }
    BannerToAlbum {
        id: bannerToAlbum
    }
    BannerRename {
        id: bannerRename
    }
    BannerSearch {
        id: bannerSearch
    }
    BannerResize {
        id: bannerResize
    }
    ListModel {
        id: idListModelImages
    }
    ListModel {
        id: idListModelImagesAlbum
    }
    ListModel {
        id: idListModelAlbums
    }
    ListModel {
        id: idListModelFolders
        property string sortColumnName: "folder_name"
        function swap(a,b) {
            if (a<b) {
                move(a,b,1);
                move (b-1,a,1);
            } else if (a>b) {
                move(b,a,1);
                move (a-1,b,1);
            }
        }
        function partition(begin, end, pivot) {
            var piv=get(pivot)[sortColumnName];
            swap(pivot, end-1);
            var store=begin;
            var ix;
            for(ix=begin; ix<end-1; ++ix) {
                if(get(ix)[sortColumnName] < piv) {
                    swap(store,ix);
                    ++store;
                }
            }
            swap(end-1, store);
            return store;
        }
        function qsort(begin, end) {
            if(end-1>begin) {
                var pivot=begin+Math.floor(Math.random()*(end-begin));
                pivot=partition( begin, end, pivot);
                qsort(begin, pivot);
                qsort(pivot+1, end);
            }
        }
        function quick_sort() {
            qsort(0,count)
        }
    }
    ListModel {
        id: idListModelImagesFolder
    }
    ListModel {
        id: idListModelSearch
    }
    ListModel {
        id: idListModelFavourites
    }
    ShareAction {
        id: shareActionZip
        mimeType: "application/zip"
    }
    Timer {
        // needed for fully returning to firstPage from settingsPage before scanning starts and blocks UI
        id: idDelayTimerApplySettingsScan4Images
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            clearAllLists() // needed?
            py.scanForImages()
        }
    }
    Timer {
        id: idCoverImageChangeTimer
        property bool firstRandomization : false
        interval: coverImageChangeInterval // [ms}
        running: infoActivateCoverImages === 1 && finishedLoading
        repeat: true
        triggeredOnStart: firstRandomization // bugfix: only run on very first time without delay, but when opening+closing context menu in albums, do not trigger randomization
        onTriggered: {
            firstRandomization = false
            randomizeCoverAlbumFolderArt()
        }
    }


    Python {
        id: py
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('../py'));
            importModule('timelinex', function () {});

            // Handlers = Signals to do something in QML whith received Infos from pyotherside
            setHandler('debugPythonLogs', function(i) {
                console.log(i)
            });
            setHandler('scanProgress', function(someCounter, imagesTotalAmount) {
                currentlyScannedImage = someCounter
                maxScannedImages = imagesTotalAmount
            });
            setHandler('returnSortedImageList2Model', function(fileList) {
                //idListModelImages.clear()
                //idListModelImagesAlbum.clear()

                // now go through file list and add all info
                for(var i = 0; i < fileList.length; i++) {
                    if (fileList[i][3] === 1) { var month2text = qsTr("January") }
                    else if (fileList[i][3] === 2) { month2text = qsTr("February") }
                    else if (fileList[i][3] === 3) { month2text = qsTr("March") }
                    else if (fileList[i][3] === 4) { month2text = qsTr("April") }
                    else if (fileList[i][3] === 5) { month2text = qsTr("May") }
                    else if (fileList[i][3] === 6) { month2text = qsTr("June") }
                    else if (fileList[i][3] === 7) { month2text = qsTr("July") }
                    else if (fileList[i][3] === 8) { month2text = qsTr("August") }
                    else if (fileList[i][3] === 9) { month2text = qsTr("September") }
                    else if (fileList[i][3] === 10) { month2text = qsTr("October") }
                    else if (fileList[i][3] === 11) { month2text = qsTr("November") }
                    else if (fileList[i][3] === 12) { month2text = qsTr("December") }
                    var newPathArray = fileList[i][1].split("/")
                    var folderPath = (newPathArray.slice(0, newPathArray.length-1)).join("/") + "/"
                    var fileName = newPathArray.slice(-1)[0]
                    var estimatedSize = Math.round ( (parseInt(fileList[i][5])/1024/1024) * 100) / 100
                    var exifAlbum = fileList[i][6]

                    // check if image is a favourite in DB
                    var isFavourite = "false"
                    for (var j = 0; j < dbFavouritesArray.length; j++) {
                        if (dbFavouritesArray[j] === fileList[i][1]) {
                            isFavourite = "true"
                        }
                    }

                    // check if image has album assigned in DB
                    var inAlbum = standardAlbum
                    for (j = 0; j < dbPathAlbumsArray.length; j++) {
                        if (dbPathAlbumsArray[j][0] === fileList[i][1]) {
                            inAlbum = dbPathAlbumsArray[j][1]
                        }
                    }

                    // overwrite this value in case album taken from EXIF
                    if ( (settingUseExif !== 0) && (exifAlbum !== "|||") ) {
                        inAlbum = exifAlbum
                    }

                    // add info to different lists
                    idListModelImages.append({
                                                "creationDateMS" : fileList[i][0],
                                                "filePath" : fileList[i][1],
                                                "monthYear" : month2text + " " + fileList[i][2],
                                                "day" : fileList[i][4],
                                                "folderPath" : folderPath,
                                                "fileName" : fileName,
                                                "estimatedSize" : estimatedSize,
                                                "album" : inAlbum,
                                                "selected" : false,
                                                "exifInfo" : fileList[i][6],
                                                "isSearchResult" : false, //true???
                                                "timestampSource" : fileList[i][7],
                                                "isFavourite" : isFavourite
                                             })
                    if (isFavourite === "true") {
                        idListModelFavourites.append({
                                                "creationDateMS" : fileList[i][0],
                                                "filePath" : fileList[i][1],
                                                "monthYear" : month2text + " " + fileList[i][2],
                                                "day" : fileList[i][4],
                                                "folderPath" : folderPath,
                                                "fileName" : fileName,
                                                "estimatedSize" : estimatedSize,
                                                "album" : inAlbum,
                                                "selected" : false,
                                                "exifInfo" : fileList[i][6],
                                                "isSearchResult" : false,
                                                "timestampSource" : fileList[i][7],
                                                "isFavourite" : isFavourite,
                                                "listModelImages_baseIndex" : i
                                             })
                    }
                }

                // re-count items still left, search results should be kept
                countDistinctAlbums()
                countDistinctFolders()
                randomizeDistinctFoldersArray()
                randomCoverImage()
                fileList = []
                dbFavouritesArray = []
                dbPathAlbumsArray = []
                finishedLoading = true //done creating list models
            });
            setHandler('goToDateIndex', function( targetListIndex ) {
                idListViewTimeline.positionViewAtIndex( targetListIndex, ListView.Center)
            });
            setHandler('returnEXIFinfoList', function( exifInfoList, availableExifInfosList, filePath, creationDateMS, monthYear, day, folderPath, fileName, estimatedSize, album, imageWidth, imageHeight, timestampSource, isFavourite ) {
                pageStack.animatorPush(fileDetailPage, {
                                           exifList : exifInfoList,
                                           availableExifInfosList : availableExifInfosList,
                                           filePath : filePath,
                                           fileName : fileName,
                                           folderPath : folderPath,
                                           creationDateMS : creationDateMS,
                                           estimatedSize : estimatedSize,
                                           album : album,
                                           imageWidth : imageWidth,
                                           imageHeight : imageHeight,
                                           timestampSource : timestampSource,
                                           isFavourite : isFavourite
                })
                //console.log(availableExifInfosList)
            });
            setHandler('finishedRenaming', function( newPath ) {
                console.log( newPath )
            });
            setHandler('removeEntryFromDB', function( inWhichTable, filePath ) {
                if (inWhichTable === "inAlbumTable") {
                    storageItem.removeAlbum(filePath)
                }
                else { // inWhichTable === "inKeywordsTable"
                    storageItem.removeKeywords(filePath)
                }
                //console.log(inWhichTable + ": " + filePath)
            });
            setHandler('finishedRemovingEntriesFromDB', function() {
                clearDBoldEntries = false
            });
            setHandler('returnCommandExists', function( command ) {
                if (command === "harbour-file-browser") {
                    fileBrowserInstalled = true
                }
                else {
                    console.log(command)
                }
            });
            setHandler('returnAmountExtPartitions', function( amountExternalPartitions ) {
                amountExtPartitions = amountExternalPartitions
                py.scanForImages() // triggered only here on startUp, otherwise scanning for external drives might take too long and would miss SD cards
            });
            setHandler('zipFileCreated', function( targetPath ) {
                //console.log(targetPath)
                finishedLoading = true
                shareActionZip.resources = [targetPath]
                shareActionZip.trigger()
            });
            setHandler('finishedWritingMetadata', function() {
                //console.log("finished writing metadata")
            });
            setHandler('pillowNotAvailable', function( reason ) {
                if (reason === "tooOld") {
                    console.log("Pillow is available but seems too OLD")
                }
                else {
                    console.log("Pillow is NOT available")
                }
                pillowAvailable = false
            });
            setHandler('batchResizeProgress', function( progressResizing ) {
                if (progressResizing >= 100) {
                    finishedLoading = true
                }
            });
            setHandler('filesDeleted', function() {
                //console.log("more than " + imagesWorkload2Rescan + " images got deleted, triggering rescan...")
                clearAllLists()
                py.scanForImages()
            });
            setHandler('updateImage', function() {
                reloadImage = true
                reloadImage = false
            });
            setHandler('updateSingleFileSize', function(filePath, newFileSize) {
                var estimatedSize = Math.round ( (parseInt(newFileSize)/1024/1024) * 100) / 100
                // update main listmodelImages
                for (var i = 0; i < idListModelImages.count; i++) {
                    if (idListModelImages.get(i).filePath === filePath) {
                        console.log("listmodelImages ID: " + i)
                        idListModelImages.setProperty(i, "estimatedSize", estimatedSize)
                    }
                }
                // update current album images list if available
                for (i = 0; i < idListModelImagesAlbum.count; i++) {
                    if (idListModelImagesAlbum.get(i).filePath === filePath) {
                        console.log("listmodel album images ID: " + i)
                        idListModelImagesAlbum.setProperty(i, "estimatedSize", estimatedSize)
                    }
                }
                // update current folder images list if available
                for (i = 0; i < idListModelImagesFolder.count; i++) {
                    if (idListModelImagesFolder.get(i).filePath === filePath) {
                        console.log("listmodel folder images ID: " + i)
                        idListModelImagesFolder.setProperty(i, "estimatedSize", estimatedSize)
                    }
                }
                // update listmodelFavourites if available
                for (i = 0; i < idListModelFavourites.count; i++) {
                    if (idListModelFavourites.get(i).filePath === filePath) {
                        console.log("listmodel favourites ID: " + i)
                        idListModelFavourites.setProperty(i, "estimatedSize", estimatedSize)
                    }
                }
                // update listmodelSearch if available
                for (i = 0; i < idListModelSearch.count; i++) {
                    if (idListModelSearch.get(i).filePath === filePath) {
                        console.log("listmodel search ID: " + i)
                        idListModelSearch.setProperty(i, "estimatedSize", estimatedSize)
                    }
                }
            });
        }

        // image editing operations
        function imageRotateFunction( filePath, targetAngle ) {
            call("timelinex.imageRotateFunction", [ filePath, targetAngle ])
        }
        function imageFlipMirrorFunction( filePath, targetDirection ) {
            call("timelinex.imageFlipMirrorFunction", [ filePath, targetDirection ])
        }
        function imageCropFunction( filePath, rectX, rectY, rectWidth, rectHeight, scaleFactor ) {
            call("timelinex.imageCropFunction", [ filePath, rectX, rectY, rectWidth, rectHeight, scaleFactor ])
        }
        function imageColorizeFunction( filePath, brightnessFactor, contrastFactor ) {
            call("timelinex.imageColorizeFunction", [ filePath, brightnessFactor, contrastFactor ])
        }
        function imageResizeFunction( filePath, targetWidth, targetHeight, targetDirection ) {
            finishedLoading = false
            call("timelinex.imageResizeFunction", [ filePath, targetWidth, targetHeight ])
        }
        function imageBulkResizeFunction( imagePathsList, targetWidth, targetHeight, targetDirection ) {
            finishedLoading = false
            call("timelinex.imageBulkResizeFunction", [ imagePathsList, targetWidth, targetHeight, targetDirection ])
        }
        function imagePaintFunction ( filePath, imageRatioSourceScreen, freeDrawPolyCoordinates, lineColorArray, lineWidthArray ) {
            call("timelinex.imagePaintFunction", [ filePath, imageRatioSourceScreen, freeDrawPolyCoordinates, lineColorArray, lineWidthArray ])
        }

        // file operations
        function scanForImages() {
            finishedLoading = false
            runSlideshowTimer = false
            // the following part could also be included on the receiving end but saves some time if done here
            idListModelImages.clear()
            idListModelImagesAlbum.clear()
            dbFavouritesArray = storageItem.getAllStoredKeywords( "noFilesAvailable" )
            dbPathAlbumsArray = storageItem.getAllStoredImagesAlbums( "noPathAvailable", "noInfoAvailable" )
            // important preparational info
            var folders2scanHOME = (storageItem.getSetting("infoFolders2scanHOME", "/Downloads|||/Pictures|||/Documents|||/android_storage")).split("|||")
            if (amountExtPartitions !== 0) {
                var folders2scanEXTERN = (storageItem.getSetting("infoFolders2scanEXTERN", "/Download|||/DCIM|||/Android")).split("|||")
            }
            else {
                folders2scanEXTERN = ""
            }
            var sdCards2scanEXTERN = (storageItem.getSetting("sdCards2scanEXTERN", "1|||1|||1")).split("|||")
            var showDirection = storageItem.getSetting("infoTimeLineDirectionIndex", "0")
            var creationModificationDate = parseInt(storageItem.getSetting("infoTimeCreationModification", 0))
            var showHiddenFiles = parseInt(storageItem.getSetting("infoTimeHiddenFiles", 0))
            settingUseExif = parseInt(storageItem.getSetting("infoTimeUseExifAlbum", 0)) // 0 = no scanning, saves time // 1 = metadata // 2= filename parsing and metadata
            call("timelinex.scanForImages", [folders2scanHOME, folders2scanEXTERN, sdCards2scanEXTERN, showDirection, creationModificationDate, showHiddenFiles, settingUseExif])
        }
        function getEXIFdata( filePath, creationDateMS, monthYear, day, folderPath, fileName, estimatedSize, album, imageWidth, imageHeight, timestampSource, isFavourite) {
            call("timelinex.getEXIFdata", [ filePath, creationDateMS, monthYear, day, folderPath, fileName, estimatedSize, album, imageWidth, imageHeight, timestampSource, isFavourite ])
        }
        function findClosestDate( targetDate ) {
            var datesItems = []
            for (var k = 0; k < idListModelImages.count; k++) {
                //console.log(idListModelImages.get(k).creationDateMS)
                datesItems.push(idListModelImages.get(k).creationDateMS)
            }
            var thisDateLocale = new Date(targetDate).toLocaleDateString(Qt.locale("de_DE"), "dd. MMMM yyyy") // weekday "dddd"
            var thisDateMS = new Date(targetDate).getTime() / 1000
            //console.log(thisDateLocale)
            //console.log(thisDateMS)
            call("timelinex.findClosestDate", [datesItems, thisDateMS])
        }
        function deleteFilesFunction( deletePathArray, imagesWorkload2Rescan ) {
            call("timelinex.deleteFilesFunction", [ deletePathArray, imagesWorkload2Rescan ])
        }
        function renameOriginalFunction( currentPath ) {
            //var currentPath = "/" + origImageFilePath.replace(/^(file:\/{3})|(qrc:\/{2})|(http:\/{2})/,"")
            //var newPath = "some_path.new"
            //call("graphx.renameOriginalFunction", [ currentPath, newPath ])
        }
        function checkDB_fileExistance() {
            // clear empty entries from "album" table
            var storedFiles_inDB_Array = storageItem.getAllStoredImages( "noFilesAvailable" )
            for (var j = 0; j < storedFiles_inDB_Array.length; j++) {
                call("timelinex.checkFileExistence", [ "inAlbumTable", storedFiles_inDB_Array[j] ])
            }
            //console.log(storedFiles_inDB_Array + "\n")
            // clear also empty entries from "keywords" table
            var storedKeywords_inKEYWORDS_Array = storageItem.getAllStoredKeywords( "noFilesAvailable" )
            for (j = 0; j < storedKeywords_inKEYWORDS_Array.length; j++) {
                call("timelinex.checkFileExistence", [ "inKeywordsTable", storedKeywords_inKEYWORDS_Array[j] ])
            }
            //console.log(storedKeywords_inKEYWORDS_Array.length )
            //console.log(storedKeywords_inKEYWORDS_Array)
        }
        function checkCMDexistance( command ) {
            call("timelinex.checkCMDexistance", [ command ])
        }
        function runCMDtool( command ) {
            call("timelinex.runCMDtool", [ command ])
        }
        function getAmountExtPartitions () {
            call("timelinex.getAmountExtPartitions", [])
        }
        function insertMetadataKeywords ( tags, filePath ) {
            var storeWhere = "in_IPTC"
            call("timelinex.insertMetadataKeywords", [ tags, filePath, storeWhere ])
        }
        function removeMetadataKeywords ( filePath ) {
            var storeWhere = "in_IPTC"
            call("timelinex.removeMetadataKeywords", [ filePath, storeWhere ])
        }
        function packZipImagesTmp ( imagePathsList ) {
            if (imagePathsList.length > 4) {
                finishedLoading = false
                call("timelinex.packZipImagesTmp", [ imagePathsList ])
            }
        }
        function editEXIFdata ( filePath, ifdZone, tagNr, tagName, tagValue ) {
            //finishedLoading = false
            call("timelinex.editEXIFdata", [ filePath, ifdZone, tagNr, tagName, tagValue ])
        }

        onError: {
            //console.log('python error: ' + traceback) //when an exception is raised, this error handler will be called
        }
        onReceived: {
            //console.log('got message from python: ' + data) //asychronous messages from Python arrive here; done there via pyotherside.send()
        }
    } // end Python


    SilicaFlickable {
        id: idSilicaFlickableFirstPage
        anchors.fill: parent
        anchors.bottomMargin: idFooterRow.height

        SilicaListView {
            id: idListViewTimeline
            visible: currentView === "timeline"
            enabled: visible
            width: parent.width
            height: parent.height
            clip: true
            spacing: Theme.paddingSmall
            quickScroll: false
            //header:
            footer: Item {
                width: parent.width
                height: (isPortrait) ? upperFreeHeight/3 : 0
            }

            //VerticalScrollDecorator {}
            ScrollBar {
                id: idScrollBarDate
                enabled: true
                labelVisible: true
                //topPadding: (isPortrait) ? upperFreeHeight/3 : 0
                topPadding: (isPortrait) ? upperFreeHeight : 0
                bottomPadding: (isPortrait) ? upperFreeHeight/3 : 0
                labelModelTag: "monthYear"
                visible: (parent.visibleArea.heightRatio < 1.0) && (idPulldownMenu.active === false) && (delegateMenuOpen === false)
            }
            PullDownMenu {
                id: idPulldownMenu
                quickSelect: true
                enabled: finishedLoading === true

                MenuItem {
                    text: qsTr("Date")
                    onClicked: {
                        var dialog = pageStack.push(datePickerComponent, { })
                        dialog.accepted.connect( function () {
                            py.findClosestDate(dialog.date)
                        } )
                    }
                }

            }
            BusyIndicator {
                anchors.centerIn: parent
                running: finishedLoading === false
                size: BusyIndicatorSize.Large
            }
            Label {
                visible: !finishedLoading
                enabled: visible
                width: parent.width
                height: upperFreeHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight //HCenter
                rightPadding: Theme.paddingLarge // * 2
                leftPadding: rightPadding
                color: finishedLoading ? Theme.highlightColor : Theme.secondaryHighlightColor
                elide: Text.ElideRight
                text: (currentlyScannedImage + "/" + maxScannedImages)
            }

            section.property: ("monthYear")
            section.criteria: ViewSection.FullString
            section.delegate: Text {
                text: section
                height: upperFreeHeight
                width: parent.width
                rightPadding: 2* Theme.paddingLarge
                leftPadding: rightPadding
                color: Theme.highlightColor
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Theme.fontSizeMedium
            }

            model: idListModelImages
            delegate: ListItem {
                width: parent.width
                contentHeight: Math.max( idListRowTimelineDescription.height, minimumTimelineListItemHeight - Theme.paddingSmall )
                contentWidth: (idListViewTimeline.visibleArea.heightRatio < 1.0) ? (parent.width - Theme.paddingLarge*2) : (parent.width)
                onClicked:  {
                    var currentImageIndex = index
                    var allCurrentModelImagePathsArray = []
                    for (var j = 0; j < idListModelImages.count; j++) {
                        allCurrentModelImagePathsArray.push(idListModelImages.get(j).filePath)
                    }
                    pageStack.animatorPush(viewPage, {
                                               upperFreeHeight : upperFreeHeight,
                                               allCurrentModelImagePathsArray : allCurrentModelImagePathsArray,
                                               currentImageIndex : currentImageIndex,
                                           })
                }

                function removeFile( filePathArray ) {
                    remorseAction(qsTr("Delete file?"), function() {
                        deleteThisImage( filePathArray, "firstPage" )
                    })
                }

                menu: Component {
                    ContextMenu {
                        MenuItem {
                            text: qsTr("Set Album")
                            onClicked: {
                                var chosenFilesArray = []
                                chosenFilesArray.push([0,filePath,index])
                                bannerToAlbum.notify( Theme.highlightDimmerColor, Theme.itemSizeHuge, chosenFilesArray, "fromTimeline", "triggeredOnFirstPage" )
                            }
                        }
                        MenuItem {
                            text: (isFavourite !== "true") ? qsTr("Set Favourite") : qsTr("From Favourite")
                            onClicked: {
                                if (isFavourite !== "true") { // add to favourites
                                    var updateType = "addFavourite"
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
                                                         "listModelImages_baseIndex" : index
                                                     })
                                }
                                else { // remove from favourites
                                    updateType = "removeFavourite"
                                }
                                var chosenFilesArray = []
                                chosenFilesArray.push(filePath)
                                updateAllLists_isFavourite ("fromFirstPage" , updateType, chosenFilesArray)
                            }
                        }
                        MenuItem {
                            text: qsTr("Open with")
                            onClicked: {
                                Qt.openUrlExternally("file:///" + filePath)
                            }
                        }
                        MenuItem {
                            text: qsTr("Share")
                            ShareAction {
                                id: shareAction
                                mimeType: "image/*"
                            }
                            onClicked: {
                                shareAction.resources = [filePath]
                                shareAction.trigger()
                            }
                        }
                        MenuItem {
                            text: qsTr("Delete")
                            onClicked: {
                                var chosenFilesArray = []
                                chosenFilesArray.push(filePath)
                                removeFile( chosenFilesArray )
                            }
                        }
                        MenuItem {
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
                onMenuOpenChanged: {
                    // set variable to disable scrollBar visibility
                    if (menuOpen === true) {
                        delegateMenuOpen = true
                    } else {
                        delegateMenuOpen = false
                    }
                }

                Row {
                    z: -1
                    x: Theme.paddingSmall / 2
                    width: parent.width - x
                    height: parent.height
                    spacing: Theme.paddingLarge

                    Image {
                        id: idImageTimeline
                        width: minimumTimelineListItemHeight - Theme.paddingSmall
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        autoTransform: true
                        fillMode: Image.PreserveAspectCrop
                        source: (reloadImage === false) ? "image://nemoThumbnail/" + filePath : ""
                        asynchronous: true
                        cache: false

                        Icon {
                            id: idIconFavourites
                            visible: isFavourite === "true"
                            highlightColor: Theme.primaryColor
                            width: parent.width / 4.5
                            height: width
                            source: "image://theme/icon-m-favorite-selected?"

                            Rectangle {
                                z: -1
                                anchors.fill: parent
                                visible: isFavourite === "true"
                                color: Theme.highlightDimmerColor
                                opacity: 0.75
                            }
                        }
                    }
                    Column {
                        id: idListRowTimelineDescription
                        width: parent.width - idImageTimeline.width - parent.spacing - Theme.paddingLarge

                        Label {
                            width: parent.width
                            font.pixelSize : Theme.fontSizeTiny
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.Wrap
                            color: Theme.highlightColor
                            text: day + ". " + monthYear
                        }
                        Label {
                            width: parent.width
                            font.pixelSize : Theme.fontSizeTiny
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.Wrap
                            text: (amountDetails === 0) ? (fileName+ " (" + estimatedSize + " MB)") : (filePath+ " (" + estimatedSize + " MB)") //.replace(fileName, "")
                        }
                        Label {
                            width: parent.width
                            font.pixelSize : Theme.fontSizeTiny
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.Wrap
                            text: qsTr("Album: ") + album
                        }
                    }
                }
            }
        }

        SilicaGridView {
            id: idGridViewAlbums
            visible: currentView === "album"
            enabled: visible
            width: parent.width
            height: parent.height
            clip: true
            cellWidth: minimumTimelineListItemHeight
            cellHeight: cellWidth
            header: Label {
                width: parent.width
                height: upperFreeHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight //HCenter
                rightPadding: Theme.paddingLarge // * 2
                leftPadding: rightPadding
                color: finishedLoading ? Theme.highlightColor : Theme.secondaryHighlightColor
                elide: Text.ElideRight
                text: finishedLoading ? (idListModelImages.count) : (currentlyScannedImage + "/" + maxScannedImages)
            }
            footer: Item {
                width: parent.width
                height: (isPortrait) ? upperFreeHeight/3 : 0
            }

            PullDownMenu {
                quickSelect: true
                enabled: finishedLoading === true

                MenuItem {
                    text: qsTr("Search")
                    onClicked: {
                        bannerSearch.notify( Theme.highlightDimmerColor )
                    }
                }
            }
            VerticalScrollDecorator {}
            BusyIndicator {
                anchors.centerIn: parent
                running: finishedLoading === false
                size: BusyIndicatorSize.Large
            }

            model: idListModelAlbums
            delegate: GridItem {
                contentWidth: minimumTimelineListItemHeight - Theme.paddingSmall
                contentHeight: contentWidth
                contentX: Theme.paddingSmall / 2
                onClicked: {
                    if (album_name !== standardSearchAlbum) {
                        var showSearchText = ""
                    }
                    else {
                        showSearchText = tempSearchText
                    }
                    getImagesInAlbum( album_name )
                    multiSelectActive = false
                    pageStack.animatorPush(albumPage, {
                                               showSearchText : showSearchText,
                                               currentModel : "albums"
                                           })
                }

                function clear( album_name, album_count ) {
                    // bugfix: remorse item, because creates width has binding loop
                    remorse.execute( qsTr("Clear Album?"), function() {
                        clearImagesInAlbum( album_name, album_count )
                    })
                }
                function deleteTheseFiles( currentView, currentNameOrFolder, intendedAction ) {
                    // bugfix: remorse item, because creates width has binding loop
                    remorse.execute( qsTr("Delete these files?"), function() {
                        getAllPathsInAlbumOrFolder(currentView, currentNameOrFolder, intendedAction)
                    })
                }

                menu: Component {
                    ContextMenu {
                        onActiveChanged: { // bugfix: stop idCoverImageChangeTimer, otherwise it closes when image changes
                            if (active) { // when menu opened
                                idCoverImageChangeTimer.stop()
                            } else { // when menu closed
                                idCoverImageChangeTimer.start()
                            }
                        }

                        MenuItem {
                            visible: (album_name !== standardAlbum && album_name !== standardSearchAlbum && album_name !== standardFavouritesAlbum )
                            text: qsTr("Rename")
                            onClicked: bannerRename.notify( Theme.highlightDimmerColor, album_name )
                        }
                        MenuItem {
                            visible: (album_name !== standardAlbum)
                            text: qsTr("Clear")
                            onClicked: clear ( album_name, album_count )
                        }
                        MenuItem {
                            text: qsTr("Share as ZIP")
                            onClicked: {
                                getAllPathsInAlbumOrFolder("albums", album_name, "createZip")
                            }
                        }
                        MenuItem {
                            visible: pillowAvailable
                            text: qsTr("Resize")
                            onClicked: {
                                getAllPathsInAlbumOrFolder("albums", album_name, "bulkResize")
                            }
                        }
                        MenuItem {
                            text: qsTr("Delete")
                            onClicked: {
                                deleteTheseFiles ("albums", album_name, "deleteFiles")
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: (album_name !== standardSearchAlbum && album_name !== standardAlbum && album_name !== standardFavouritesAlbum) ? (Theme.rgba(Theme.primaryColor, 0.15)) : (Theme.secondaryHighlightColor) }
                        GradientStop { position: 1; color: Theme.rgba(Theme.primaryColor, 0.02) }
                    }

                    Image {
                        id: idCoverAlbum
                        visible: infoActivateCoverImages !== 0 && finishedLoading
                        anchors.fill: parent
                        width: Theme.iconSizeLarge
                        height: Theme.iconSizeLarge
                        sourceSize.width: width
                        sourceSize.height: height
                        smooth: true
                        asynchronous: true
                        autoTransform: true
                        fillMode: Image.PreserveAspectCrop
                        source: ((random_image !== undefined) && (random_image !== "") ) ? ("image://nemoThumbnail/" + random_image) : ""
                        //onSourceChanged: opacityAlbumImage.start()
                    }
                    Image {
                        visible: infoActivateCoverImages !== 0 && finishedLoading
                        anchors.fill: parent
                        width: Theme.iconSizeLarge
                        height: Theme.iconSizeLarge
                        sourceSize.width: width
                        sourceSize.height: height
                        smooth: true
                        asynchronous: true
                        autoTransform: true
                        fillMode: Image.PreserveAspectCrop
                        source: (previous_image !== "") ? ("image://nemoThumbnail/" + previous_image) : ""
                        NumberAnimation on opacity {
                            id: opacityAlbumImage
                            from: 1
                            to: 0
                            duration: 1000
                        }
                    }
                }
                Label {
                    visible: !idCoverAlbum.visible
                    anchors.fill: parent
                    anchors.bottomMargin: 0
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    truncationMode: TruncationMode.Elide
                    font.pixelSize: infoWidthDevider === 2 ? Theme.fontSizeHuge : Theme.fontSizeExtraLarge
                    text: album_count
                }
                Label {
                    visible: !idCoverAlbum.visible
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: infoWidthDevider === 2 ? (parent.height/6) : (infoWidthDevider === 3 ? parent.height/7 : parent.height/12)
                    truncationMode: TruncationMode.Elide
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: infoWidthDevider === 2 ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall
                    text: (album_name[0] === "." && (album_name === standardAlbum || album_name === standardFavouritesAlbum || album_name === standardSearchAlbum))
                          ? (album_name.substring(1))
                          : (album_name)
                }
                Label {
                    visible: album_name === standardSearchAlbum && !idCoverAlbum.visible
                    width: parent.width
                    anchors.top: parent.top
                    anchors.topMargin: infoWidthDevider === 2 ? (parent.height/6) : (infoWidthDevider === 3 ? parent.height/7 : parent.height/12)
                    truncationMode: TruncationMode.Elide
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: (infoWidthDevider === 2 ? Theme.fontSizeSmall : Theme.fontSizeExtraSmall)
                    font.italic: true
                    text: tempSearchText
                }
                Label {
                    visible: idCoverAlbum.visible
                    width: parent.width
                    anchors.bottom: parent.bottom
                    truncationMode: TruncationMode.Elide
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: infoWidthDevider === 2 ? Theme.fontSizeMedium : Theme.fontSizeExtraSmall
                    text: (album_name[0] === "." && (album_name === standardAlbum || album_name === standardFavouritesAlbum || album_name === standardSearchAlbum))
                          ? ( (album_name.substring(1)) + " - " + album_count )
                          : ( album_name + " - " + album_count )
                    Rectangle {
                        z: -1
                        visible: idCoverAlbum.visible
                        anchors.centerIn: parent
                        height: parent.paintedHeight
                        width: (parent.width > (parent.paintedWidth+0.6*parent.paintedHeight)) // 0.9
                                ? (parent.paintedWidth + 0.6*parent.paintedHeight)  // 0.9
                                : (parent.width)
                        color: Theme.rgba(Theme.highlightBackgroundColor, 1)
                    }
                }
            }
        }

        SilicaListView {
            id: idListViewFolders
            visible: currentView === "folder"
            enabled: visible
            width: parent.width
            height: parent.height
            spacing: Theme.paddingSmall
            clip: true
            header: Label {
                width: parent.width
                height: upperFreeHeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight //HCenter
                rightPadding: Theme.paddingLarge // * 2
                leftPadding: rightPadding
                color: finishedLoading ? Theme.highlightColor : Theme.secondaryHighlightColor
                text: finishedLoading ? (idListModelImages.count + " | " + idListModelFolders.count) : (currentlyScannedImage + "/" + maxScannedImages)
            }
            footer: Item {
                width: parent.width
                height: (isPortrait) ? upperFreeHeight/3 : 0
            }

            PullDownMenu {
                quickSelect: true
                enabled: finishedLoading === true

                MenuItem {
                    enabled: fileBrowserInstalled
                    text: (fileBrowserInstalled) ? qsTr("File Browser") : qsTr("File Browser not installed")
                    onClicked: {
                        py.runCMDtool("harbour-file-browser")
                    }
                }
            }
            VerticalScrollDecorator {}
            BusyIndicator {
                anchors.centerIn: parent
                running: finishedLoading === false
                size: BusyIndicatorSize.Large
            }

            model: idListModelFolders
            delegate: ListItem {
                width: parent.width
                contentHeight: Math.max( idListRowDescription.height, minimumFolderListItemHeight )
                onClicked: {
                    var showSearchText = ""
                    getImagesInFolder( folder_name )
                    pageStack.animatorPush(albumPage, {
                                               showSearchText : showSearchText,
                                               currentModel : "folders"
                                           })
                }
                function deleteTheseFiles( currentView, currentNameOrFolder, intendedAction ) {
                    remorseAction( qsTr("Delete these files?"), function() {
                        getAllPathsInAlbumOrFolder(currentView, currentNameOrFolder, intendedAction)
                    })
                }
                menu: Component {
                    ContextMenu {
                        MenuItem {
                            text: qsTr("Set Album")
                            onClicked: {
                                var chosenFilesArray = []
                                getImagesInFolder( folder_name )
                                for (var j = 0; j < idListModelImagesFolder.count; j++) {
                                    var targetIndex_FolderOrAlbum = j
                                    chosenFilesArray.push( [targetIndex_FolderOrAlbum, idListModelImagesFolder.get(j).filePath, idListModelImagesFolder.get(j).listModelImages_baseIndex] )
                                }
                                bannerToAlbum.notify( Theme.highlightDimmerColor, Theme.itemSizeHuge, chosenFilesArray, "fromFolder", "triggeredOnFirstPage" )
                            }
                        }
                        MenuItem {
                            text: qsTr("Share as ZIP")
                            onClicked: {
                                getAllPathsInAlbumOrFolder("folders", folder_name, "createZip")
                            }
                        }
                        MenuItem {
                            visible: pillowAvailable
                            text: qsTr("Resize")
                            onClicked: {
                                getAllPathsInAlbumOrFolder("folders", folder_name, "bulkResize")
                            }
                        }
                        MenuItem {
                            text: qsTr("Delete")
                            onClicked: {
                                deleteTheseFiles ("folders", folder_name, "deleteFiles")
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: parent.height

                    Label {
                        id: idLabelAmountImagesFolder
                        visible: idCoverFolder.visible
                        width: parent.width / 7
                        rightPadding: Theme.paddingLarge
                        anchors.verticalCenter: parent.verticalCenter
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignRight
                        font.pixelSize : infoWidthDevider === 2 ? Theme.fontSizeLarge : Theme.fontSizeMedium
                        color: Theme.secondaryColor
                        text: folder_count
                    }
                    Rectangle {
                        id: idListRowFolder
                        width: minimumFolderListItemHeight
                        height: Math.max( idListRowDescription.height, minimumFolderListItemHeight )
                        gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.rgba(Theme.primaryColor, 0.15) }
                                GradientStop { position: 1; color: Theme.rgba(Theme.primaryColor, 0.02) }
                        }

                        Image {
                            id: idCoverFolder
                            visible: infoActivateCoverImages !== 0 && finishedLoading
                            anchors.fill: parent
                            width: Theme.iconSizeLarge
                            height: Theme.iconSizeLarge
                            sourceSize.width: width
                            sourceSize.height: height
                            smooth: true
                            autoTransform: true
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            source: ((random_image !== undefined) && (random_image !== "") ) ? ("image://nemoThumbnail/" + random_image) : ""
                            onSourceChanged: opacityFolderImage.start()
                        }
                        Image {
                            visible: infoActivateCoverImages !== 0 && finishedLoading
                            anchors.fill: parent
                            width: Theme.iconSizeLarge
                            height: Theme.iconSizeLarge
                            sourceSize.width: width
                            sourceSize.height: height
                            smooth: true
                            autoTransform: true
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            onOpacityChanged:
                                if (opacity === 0) {
                                    source = idCoverFolder.source
                                    opacity = 1
                                }
                            NumberAnimation on opacity {
                                id: opacityFolderImage
                                from: 1
                                to: 0
                                duration: 1000
                            }
                        }
                        Label {
                            visible: !idCoverFolder.visible
                            height: parent.height
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            truncationMode: TruncationMode.Elide
                            font.pixelSize: infoWidthDevider === 2 ? Theme.fontSizeLarge : Theme.fontSizeMedium //Theme.fontSizeMedium
                            text: folder_count
                        }
                    }
                    Label {
                        id: idListRowDescription
                        width: (idCoverFolder.visible) ? (parent.width - idLabelAmountImagesFolder.width - idListRowFolder.width) : (parent.width - idListRowFolder.width)
                        leftPadding: Theme.paddingLarge
                        rightPadding: leftPadding //* 2
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize : Theme.fontSizeTiny
                        wrapMode: Text.Wrap
                        text: folder_name
                    }
                }
            }
        }
    }

    Rectangle {
        id: idFooterRow
        y: appHeight - height
        width: page.width
        height: Theme.itemSizeMedium
        color: Theme.highlightDimmerColor

        Row {
            anchors.fill: parent

            Label {
                width: parent.width / 7 * 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeLarge
                color: (currentView === "timeline") ? (finishedLoading ? Theme.highlightColor : Theme.secondaryHighlightColor) : (finishedLoading ? Theme.primaryColor : Theme.secondaryColor)
                text: qsTr("Timeline")

                MouseArea {
                    enabled: finishedLoading
                    anchors.fill: parent
                    onClicked: {
                        currentView = "timeline"
                        storageItem.setSetting("infoCurrentView", "timeline")
                    }
                }
            }
            Label {
                width: parent.width / 7* 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeLarge
                color: (currentView === "album") ? (finishedLoading ? Theme.highlightColor : Theme.secondaryHighlightColor) : (finishedLoading ? Theme.primaryColor : Theme.secondaryColor)
                text: qsTr("Album")

                MouseArea {
                    enabled: finishedLoading
                    anchors.fill: parent
                    onClicked: {
                        currentView = "album"
                        storageItem.setSetting("infoCurrentView", "album")
                    }
                }
            }
            Label {
                width: parent.width / 7* 2
                height: parent.height
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                truncationMode: TruncationMode.Fade
                font.pixelSize: Theme.fontSizeLarge
                color: (currentView === "folder") ? (finishedLoading ? Theme.highlightColor : Theme.secondaryHighlightColor) : (finishedLoading ? Theme.primaryColor : Theme.secondaryColor)
                text: qsTr("Folder")

                MouseArea {
                    enabled: finishedLoading
                    anchors.fill: parent
                    onClicked: {
                        currentView = "folder"
                        storageItem.setSetting("infoCurrentView", "folder")
                    }
                }
            }
            IconButton {
                enabled: finishedLoading
                width: parent.width / 7
                height: parent.height
                icon.scale: 0.9
                icon.color: Theme.primaryColor
                icon.source: "image://theme/icon-m-developer-mode?"
                onClicked: {
                    pageStack.animatorPush(Qt.resolvedUrl("SettingsPage.qml"), {
                        standardScreenHeight : standardScreenHeight,
                        amountExtPartitions : amountExtPartitions,
                    })
                }
                onPressAndHold: {
                    rumbleEffect.start()
                    clearAllLists()
                    py.scanForImages()
                    py.checkDB_fileExistance()
                }
            }
        }
    }

    // necessary functions
    function randomIntFromInterval(min, max) { // min and max included
      return Math.floor(Math.random() * (max - min + 1) + min)
    }

    function clearAllLists() {
        idListModelImages.clear()
        idListModelImagesAlbum.clear()
        idListModelAlbums.clear()
        idListModelFolders.clear()
        idListModelImagesFolder.clear()
        idListModelSearch.clear()
        idListModelFavourites.clear()
    }

    function countDistinctAlbums() {
        // clear listmodel and re-create it with new values
        idListModelAlbums.clear()
        var allAlbumsArray = []
        var prev_album_found = ""
        for (var i = 0; i < idListModelImages.count; i++) {
            var album_value = idListModelImages.get(i).album
            if (album_value !== prev_album_found) {
                allAlbumsArray.push(album_value)
                prev_album_found = album_value
            }
        }
        if (idListModelSearch.count > 0) {
            allAlbumsArray.push( standardSearchAlbum ) // visible when there are search results
        }
        if (idListModelFavourites.count > 0) {
            allAlbumsArray.push( standardFavouritesAlbum ) // visible when there are favorites
        }
        distinctAlbums = (allAlbumsArray.filter(function(v,i) { return i===allAlbumsArray.lastIndexOf(v); }))
        distinctAlbums = distinctAlbums.sort()

        // count items and assign a random image
        for (var j = 0; j < distinctAlbums.length; j++) {
            var counter = 0
            var randomIndex
            var randomFilePath = ""

            // search album
            if (distinctAlbums[j] === standardSearchAlbum) {
                counter = idListModelSearch.count
                if (counter > 0 && infoActivateCoverImages) {
                    randomIndex = randomIntFromInterval(0, counter-1)
                    randomFilePath = idListModelSearch.get(randomIndex).filePath
                }
            }
            // favourites album
            else if (distinctAlbums[j] === standardFavouritesAlbum) {
                counter = idListModelFavourites.count
                if (counter > 0 && infoActivateCoverImages) {
                    randomIndex = randomIntFromInterval(0, counter-1)
                    randomFilePath = idListModelFavourites.get(randomIndex).filePath
                }
            }
            // other albums
            else {
                var tempFileArray = []
                for (var c = 0; c < idListModelImages.count; c++) {
                    if (idListModelImages.get(c).album === distinctAlbums[j]) {
                        counter += 1
                        if ((counter > 0 && infoActivateCoverImages)) {
                            tempFileArray.push(idListModelImages.get(c).filePath)
                        }
                    }
                }
                if (infoActivateCoverImages) {
                    randomIndex = randomIntFromInterval(0, tempFileArray.length-1)
                    randomFilePath = tempFileArray[randomIndex]
                    tempFileArray = []
                }

            }

            // now add to album listmodel
            idListModelAlbums.append({ "album_name" : distinctAlbums[j],
            //idListModelAlbums.set(j,{ "album_name" : distinctAlbums[j],
                                       "album_count" : counter,
                                       "random_image" : randomFilePath,
                                       "previous_image" : (previousRandomImagesAlbumArray[j] !== undefined) ? previousRandomImagesAlbumArray[j] : ""
                                     })
            tempFileArray = []
            // store that info in an array as well which we can use next time
            previousRandomImagesAlbumArray[j] = randomFilePath
        }
        //console.log(previousRandomImagesAlbumArray)
    }

    function countDistinctFolders() {
        var uniqueFoldersArray = []
        var uniqueFoldersCounterArray = []
        idListModelFolders.clear() // creates trouble, sometimes scrolls list back up to zero on randomizing ... how to avoid that???

        for (var i = 0; i < idListModelImages.count; i++) {
            var tempFolderPath = idListModelImages.get(i).folderPath
            var tempFilePath = idListModelImages.get(i).filePath
            var tempUniqueFolderArrayIndex = uniqueFoldersArray.indexOf( tempFolderPath )

            if (tempUniqueFolderArrayIndex > -1) { // already in listmodel
                // raise the file counter +1
                uniqueFoldersCounterArray[tempUniqueFolderArrayIndex] = uniqueFoldersCounterArray[tempUniqueFolderArrayIndex] + 1
                idListModelFolders.setProperty( tempUniqueFolderArrayIndex, "folder_count", uniqueFoldersCounterArray[tempUniqueFolderArrayIndex])
                // update the list of available file paths
                var prevListFilesInFolder = idListModelFolders.get(tempUniqueFolderArrayIndex).folder_files_all
                idListModelFolders.setProperty( tempUniqueFolderArrayIndex, "folder_files_all", prevListFilesInFolder + "|||" + tempFilePath)
                prevListFilesInFolder = ""
            }
            else { // not yet in listmodel
                uniqueFoldersArray.push( tempFolderPath )
                uniqueFoldersCounterArray.push( 1 )
                idListModelFolders.append({ "folder_name" : tempFolderPath,
                                            "folder_count" : 1,
                                            "folder_files_all" : tempFilePath,
                                            "random_image" : "",
                                          })
            }
        }
        // now sort listmodel alphabetically and cleanup
        idListModelFolders.quick_sort()
        uniqueFoldersArray = []
        uniqueFoldersCounterArray = []
    }

    function randomizeDistinctFoldersArray() {
        if (infoActivateCoverImages) {
            for (var i = 0; i < idListModelFolders.count; i++) {
                var allFilesInFolderArray = ( idListModelFolders.get(i).folder_files_all ).split("|||")
                var randomIndex = randomIntFromInterval(0, allFilesInFolderArray.length-1)
                var randomFilePath = allFilesInFolderArray[randomIndex]
                //console.log(randomFilePath)
                idListModelFolders.setProperty( i, "random_image", randomFilePath)
            }
        }
    }

    function getImagesInAlbum( albumName ) {
        currentAlbum = albumName
        idListModelImagesAlbum.clear()

        if (albumName !== standardSearchAlbum && albumName !== standardFavouritesAlbum) {
            for (var i = 0; i < idListModelImages.count; i++) {
                if ( (idListModelImages.get(i).album) === albumName ) {
                    idListModelImagesAlbum.append({
                        "creationDateMS" : idListModelImages.get(i).creationDateMS,
                        "filePath" : idListModelImages.get(i).filePath,
                        "monthYear" : idListModelImages.get(i).monthYear,
                        "day" : idListModelImages.get(i).day,
                        "folderPath" : idListModelImages.get(i).folderPath,
                        "fileName" : idListModelImages.get(i).fileName,
                        "estimatedSize" : idListModelImages.get(i).estimatedSize,
                        "album" : idListModelImages.get(i).album,
                        "selected" : false,
                        "exifInfo" :  idListModelImages.get(i).album,
                        "isSearchResult" : false,
                        "timestampSource" : idListModelImages.get(i).timestampSource,
                        "isFavourite" : idListModelImages.get(i).isFavourite,
                        "listModelImages_baseIndex" : i
                    })
                }
            }
        }

        else if (albumName === standardFavouritesAlbum) {
            //console.log("favourites")
            for (i = 0; i < idListModelFavourites.count; i++) {
                idListModelImagesAlbum.append({
                    "creationDateMS" : idListModelFavourites.get(i).creationDateMS,
                    "filePath" : idListModelFavourites.get(i).filePath,
                    "monthYear" : idListModelFavourites.get(i).monthYear,
                    "day" : idListModelFavourites.get(i).day,
                    "folderPath" : idListModelFavourites.get(i).folderPath,
                    "fileName" : idListModelFavourites.get(i).fileName,
                    "estimatedSize" : idListModelFavourites.get(i).estimatedSize,
                    "album" : idListModelFavourites.get(i).album,
                    "selected" : false,
                    "exifInfo" :  idListModelFavourites.get(i).album,
                    "isSearchResult" : false,
                    "timestampSource" : idListModelFavourites.get(i).timestampSource,
                    "isFavourite" : idListModelFavourites.get(i).isFavourite,
                    "listModelImages_baseIndex" : idListModelFavourites.get(i).listModelImages_baseIndex
                })
            }
        }

        else { // must be search results then
            //console.log("search")
            for (i = 0; i < idListModelSearch.count; i++) {
                idListModelImagesAlbum.append({
                    "creationDateMS" : idListModelSearch.get(i).creationDateMS,
                    "filePath" : idListModelSearch.get(i).filePath,
                    "monthYear" : idListModelSearch.get(i).monthYear,
                    "day" : idListModelSearch.get(i).day,
                    "folderPath" : idListModelSearch.get(i).folderPath,
                    "fileName" : idListModelSearch.get(i).fileName,
                    "estimatedSize" : idListModelSearch.get(i).estimatedSize,
                    "album" : idListModelSearch.get(i).album,
                    "selected" : false,
                    "exifInfo" :  idListModelSearch.get(i).album,
                    "isSearchResult" : idListModelSearch.get(i).isSearchResult,
                    "timestampSource" : idListModelSearch.get(i).timestampSource,
                    "isFavourite" : idListModelSearch.get(i).isFavourite,
                    "listModelImages_baseIndex" : idListModelSearch.get(i).listModelImages_baseIndex
                })
            }
        }
    }

    function clearImagesInAlbum ( albumName, albumCount ) {

        // search album
        if (albumName === standardSearchAlbum) {
            idListModelSearch.clear()
        }

        // favourites album
        else if (albumName === standardFavouritesAlbum) {
            idListModelFavourites.clear()

            // update main image list
            for (var i = 0; i < idListModelImages.count; i++) {
                if (idListModelImages.get(i).isFavourite !== "false") {
                    idListModelImages.setProperty(i, "isFavourite", "false")
                    storageItem.removeKeywords(idListModelImages.get(i).filePath)
                }
            }

            // update current album list
            for (var l = 0; l < idListModelImagesAlbum.count; l++) {
                if (idListModelImagesAlbum.get(l).isFavourite !== "false") {
                    idListModelImagesAlbum.setProperty(l, "isFavourite", "false")
                }
            }

            // update current folder list
            for (l = 0; l < idListModelImagesFolder.count; l++) {
                if (idListModelImagesFolder.get(l).isFavourite !== "false") {
                    idListModelImagesFolder.setProperty(l, "isFavourite", "false")
                }
            }

            // possibly update search results list as well
            for (l = 0; l < idListModelSearch.count; l++) {
                if (idListModelSearch.get(l).isFavourite !== "false") {
                    idListModelSearch.setProperty(l, "isFavourite", "false")
                }
            }

        }

        // all user albums
        else {
            // remove all album entry by resetting Album to default value "UNSORTED", also update DB
            for (var k = 0; k < idListModelImages.count; k++) {
                if (idListModelImages.get(k).album === albumName) {
                    idListModelImages.setProperty(k, "album", standardAlbum)
                    storageItem.removeAlbum(idListModelImages.get(k).filePath)
                    // also remove IPTC keywords if available
                    if (settingUseExif !== 0) {
                        py.removeMetadataKeywords(idListModelImages.get(k).filePath)
                    }
                }
            }

            // update favouritesModel as well
            if (idListModelFavourites.count > 0) {
                for ( k = 0; k < idListModelFavourites.count; k++) {
                    if (idListModelFavourites.get(k).album === albumName) {
                        idListModelFavourites.setProperty(k, "album", standardAlbum)
                    }
                }
            }

            // update searchModel as well
            if (idListModelSearch.count > 0) {
                for ( k = 0; k < idListModelSearch.count; k++) {
                    if (idListModelSearch.get(k).album === albumName) {
                        idListModelSearch.setProperty(k, "album", standardAlbum)
                    }
                }
            }

            // finally remove album from distinct album list when empty
            for (var j = idListModelAlbums.count -1; j >= 0; --j) {
                if (idListModelAlbums.get(j).album_name === albumName) {
                    idListModelAlbums.remove(j)
                }
            }
        }

        // start new counting of albums
        if (idListModelSearch.count < 1) {
            countDistinctAlbums( "standard" )
        }
        else {
                countDistinctAlbums( "fromSearch" )
            }
    }

    function getImagesInFolder( folderName ) {
        currentFolder = folderName
        idListModelImagesFolder.clear()

        for (var i = 0; i < idListModelImages.count; i++) {
            if ( (idListModelImages.get(i).folderPath) === folderName ) {
                idListModelImagesFolder.append({
                    "creationDateMS" : idListModelImages.get(i).creationDateMS,
                    "filePath" : idListModelImages.get(i).filePath,
                    "monthYear" : idListModelImages.get(i).monthYear,
                    "day" : idListModelImages.get(i).day,
                    "folderPath" : idListModelImages.get(i).folderPath,
                    "fileName" : idListModelImages.get(i).fileName,
                    "estimatedSize" : idListModelImages.get(i).estimatedSize,
                    "album" : idListModelImages.get(i).album,
                    "selected" : false,
                    "exifInfo" :  idListModelImages.get(i).album,
                    "isSearchResult" : false,
                    "timestampSource" : idListModelImages.get(i).timestampSource,
                    "isFavourite" : idListModelImages.get(i).isFavourite,
                    "listModelImages_baseIndex" : i
                })
            }
        }
    }

    function deleteThisImage ( filePathArray, fromPage ) {

        // buxfix: if there are too many files the UI gets blocked by the below, so use only if there are few imges to delete at once
        if (filePathArray.length < imagesWorkload2Rescan) {

            // cycle through all files individually
            for (var j = 0; j < filePathArray.length; j++) {
                var filePath = filePathArray[j]

                // remove from DB, checks automatically if available or not
                storageItem.removeAlbum(filePath)

                // remove from main image list
                for (var i = idListModelImages.count -1; i >= 0; --i) {
                    if (idListModelImages.get(i).filePath === filePath) {
                        idListModelImages.remove(i)
                    }
                }

                // remove from current album list
                for (var k = idListModelImagesAlbum.count -1; k >= 0; --k) {
                    if (idListModelImagesAlbum.get(k).filePath === filePath) {
                        idListModelImagesAlbum.remove(k)
                    }
                }

                // remove from current folder list
                for ( var o = idListModelImagesFolder.count -1; o >= 0; --o) {
                    if (idListModelImagesFolder.get(o).filePath === filePath) {
                        idListModelImagesFolder.remove(o)
                    }
                }

                // possibly remove from search results list as well
                for ( var l = idListModelSearch.count -1; l >= 0; --l) {
                    if (idListModelSearch.get(l).filePath === filePath) {
                        idListModelSearch.remove(l)
                    }
                }

                // possibly remove from favourites list as well and from its DB entry
                for ( l = idListModelFavourites.count -1; l >= 0; --l) {
                    if (idListModelFavourites.get(l).filePath === filePath) {
                        idListModelFavourites.remove(l)
                        storageItem.removeKeywords(filePath)
                    }
                }
            }
            // then remove physical file
            py.deleteFilesFunction( filePathArray, imagesWorkload2Rescan)

            // re-count items still left, search results should be kept
            countDistinctAlbums()

            // remove album and close album-page, if it was last image available
            if (idListModelImagesAlbum.count < 1) {
                for ( var m = idListModelAlbums.count -1; m >= 0; --m) {
                    if ((idListModelAlbums.get(m).album_name === currentAlbum) && (currentAlbum !== standardFavouritesAlbum) && (currentAlbum !== standardAlbum)) {
                        idListModelAlbums.remove(m)
                    }
                }
                if (fromPage === "albumPage") { pageStack.pop() }
            }

            // re-count items still left in folders
            countDistinctFolders()
            randomizeDistinctFoldersArray()

            // remove folder from list, if it was last image available
            if (idListModelImagesFolder.count < 1) {
                for ( var n = idListModelFolders.count -1; n >= 0; --n) {
                    if (idListModelFolders.get(n).folder_name === currentFolder) {
                        idListModelFolders.remove(n)
                    }
                }
                if (fromPage === "folderPage") { pageStack.pop() }
            }
        }
        // bugfix: if there are too many images 2 delete, the list counting takes too long and blocks UI, we therefore just call a complete rescan from Python side to fill up lists
        else {
            // remove images from DB
            for (j = 0; j < filePathArray.length; j++) {
                storageItem.removeAlbum(filePathArray[j])
            }
            // batch delete images in Py
            py.deleteFilesFunction( filePathArray, imagesWorkload2Rescan)
        }
    }

    function updateAllLists_isFavourite( fromPage, action, filePathArray ) {
        for (var j = 0; j < filePathArray.length; j++) {
            var filePath = filePathArray[j]

            if (action === "addFavourite") {
                var valueIsFavourite = "true"
                // make new DB entry
                storageItem.addKeywords(filePath, "true")
            }
            else { // action === "removeFavourite from all lists"
                valueIsFavourite = "false"
                // remove from favourites list first and from DB
                for ( var l = idListModelFavourites.count -1; l >= 0; --l) {
                    if (idListModelFavourites.get(l).filePath === filePath) {
                        storageItem.removeKeywords(filePath)
                        idListModelFavourites.remove(l)
                    }
                }
            }

            // update main image list
            for (l = 0; l < idListModelImages.count; l++) {
                if (idListModelImages.get(l).filePath === filePath) {
                    idListModelImages.setProperty(l, "isFavourite", valueIsFavourite)
                }
            }

            // update current album list
            for ( l = idListModelImagesAlbum.count -1; l >= 0; --l) {
                if (idListModelImagesAlbum.get(l).filePath === filePath) {
                    // only when called from inside favourites album, remove from that list, otherwise just mark as non-favourite
                    if (fromPage === "fromFavouritesAlbum") {
                        idListModelImagesAlbum.remove(l)
                        if (idListModelImagesAlbum.count < 1) {
                            pageStack.pop()
                        }
                    }
                    // otherwise just change its property isFavourite
                    else {
                        idListModelImagesAlbum.setProperty(l, "isFavourite", valueIsFavourite)
                    }
                }
            }

            // update current folder list
            for (l = 0; l < idListModelImagesFolder.count; l++) {
                if (idListModelImagesFolder.get(l).filePath === filePath) {
                    idListModelImagesFolder.setProperty(l, "isFavourite", valueIsFavourite)
                }
            }

            // possibly update search results list as well
            for (l = 0; l < idListModelSearch.count; l++) {
                if (idListModelSearch.get(l).filePath === filePath) {
                    idListModelSearch.setProperty(l, "isFavourite", valueIsFavourite)
                }
            }
        }
        countDistinctAlbums()
    }

    function getAllPathsInAlbumOrFolder(currentView, currentNameOrFolder, intendedAction) {
        // collect all affected file paths
        var imagePathsList = ""
        if (currentView === "albums") {
            // case favourites album
            if (currentNameOrFolder === standardFavouritesAlbum) {
                for (var i = 0; i < idListModelFavourites.count; i++) {
                    imagePathsList = imagePathsList + (idListModelFavourites.get(i).filePath).toString() + "|||"
                }
            }
            // case search album
            if (currentNameOrFolder === standardSearchAlbum) {
                for (i = 0; i < idListModelSearch.count; i++) {
                    imagePathsList = imagePathsList + (idListModelSearch.get(i).filePath).toString() + "|||"
                }
            }
            // all other albums
            else {
                for (i = 0; i < idListModelImages.count; i++) {
                    if ( (idListModelImages.get(i).album) === currentNameOrFolder ) {
                        //console.log("pack any other album")
                        imagePathsList = imagePathsList + (idListModelImages.get(i).filePath).toString() + "|||"
                    }
                }
            }
        }
        else { // view: folders
            for (i = 0; i < idListModelImages.count; i++) {
                if ( (idListModelImages.get(i).folderPath) === currentNameOrFolder ) {
                    imagePathsList = imagePathsList + (idListModelImages.get(i).filePath).toString() + "|||"
                }
            }
        }

        // intention...
        if (intendedAction === "createZip") {
            py.packZipImagesTmp( imagePathsList )
        }
        else if (intendedAction === "deleteFiles") {
            var chosenFilesArray = []
            if (imagePathsList.slice(-3) === "|||") {
                imagePathsList = imagePathsList.slice(0, -3)
            }
            chosenFilesArray = imagePathsList.split("|||")
            //console.log(chosenFilesArray)
            deleteThisImage( chosenFilesArray, "firstPage" )
        }
        else if (intendedAction === "bulkResize") {
            var startWidth = 1920
            var startHeight = 1920
            if (imagePathsList.slice(-3) === "|||") {
                imagePathsList = imagePathsList.slice(0, -3)
            }
            bannerResize.notify( startWidth, startHeight, imagePathsList )
        }
    }

    function unselectAll() {
        //console.log("fake function, called from bannerResize.hide(), but does nothing here, only on albumPage")
    }

    function randomCoverImage() {
        function randomIntFromInterval(min, max) { // min and max included
          return Math.floor(Math.random() * (max - min + 1) + min)
        }
        var randomIndex = randomIntFromInterval(0, idListModelImages.count-1)
        if (idListModelImages.count !== 0) {
            coverImagePath = (idListModelImages.get(randomIndex).filePath).toString()
        } else {
            coverImagePath = ""
        }
    }

    function randomizeCoverAlbumFolderArt() {
        // randomizing app cover image always
        if (!runSlideshowTimer && coverpageActiveFocus) {
            //console.log("cover active, randomizing image")
            randomCoverImage()
        }

        // also assign new random covers for albums while visible
        if (page.activeFocus && currentView === "album") {
            //console.log("randomizing album art")
            countDistinctAlbums()
        }

        // also assign new random covers for folders while visible
        if (page.activeFocus && currentView === "folder") {
            //console.log("randomizing folder art")
            randomizeDistinctFoldersArray()
        }
    }
}
