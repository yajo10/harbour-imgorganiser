import QtQuick 2.6
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0


Page {
    id: imagePage
    // values from previous page
    property var upperFreeHeight
    property var allCurrentModelImagePathsArray
    property var currentImageIndex

    // own values
    property color buttonBackgroundColor: Theme.rgba(Theme.highlightDimmerColor, 1)
    property var currentImagePath : allCurrentModelImagePathsArray[currentImageIndex]
    property bool finishedLoadingView : false
    property real minMouseMoveXSwipeImage : Theme.itemSizeMedium
    property real flickScale : flick.contentWidth / flick.width
    property bool firstTimeLoading : true
    property bool pinchEnabled : true

    property real imageSourceWidth : idImageView.sourceSize.width
    property real imageSourceHeight : idImageView.sourceSize.height
    property real imagePaintedWidth : idImageView.paintedWidth
    property real imagePaintedHeight : idImageView.paintedHeight

    property real imageRatioSourceScreen : imageSourceWidth / imagePaintedWidth


    // slideshow
    property real slideshowTimerProgress : 0
    property real targetDateMS

    allowedOrientations: Orientation.All
    backNavigation: false
    onOrientationChanged: {
        if (firstTimeLoading === false) {
            // had to exchange flick.width with flick.height at every occurance in this line ... why?
            flick.resizeContent(flick.height, flick.width, Qt.point(flick.height/2, flick.width/2))
            flick.returnToBounds()
        }
    }
    backgroundColor: "black"
    Component.onCompleted: {
        viewpageActiveFocus = true
    }
    Component.onDestruction: {
        viewpageActiveFocus = false
    }

    Timer {
        id: idSlideshowChangeTimer
        interval: coverImageChangeInterval // [ms}
        running: runSlideshowTimer && finishedLoading
        repeat: true
        onRunningChanged: {
            // first start also triggers a reset of the progress bar
            if (running === true) {
                resetCountdownTimer()
            }
        }
        onTriggered: {
            if (currentImageIndex < allCurrentModelImagePathsArray.length-1) {
                currentImageIndex = currentImageIndex + 1
                resetCountdownTimer()
            }
            else {
                animateRightListEnd.start()
                stopSlideshow()
            }
        }
    }
    Timer {
        id: idTimerClock
        interval: 10
        running: idSlideshowChangeTimer.running
        repeat: true
        onRunningChanged: {
            // first start also triggers a reset of the progress bar
            if (running === true) {
                var nowDateMS = new Date().getTime()
                slideshowTimerProgress = (targetDateMS - nowDateMS) / coverImageChangeInterval
            }
        }
        onTriggered: {
            var nowDateMS = new Date().getTime()
            slideshowTimerProgress = (targetDateMS - nowDateMS) / coverImageChangeInterval
        }
    }
    BannerTools {
        id: bannerTools
    }
    BannerCrop {
        id: bannerCrop
    }
    BannerColorize {
        id: bannerColorize
    }
    BannerResize {
        id: bannerResize
    }
    BannerPaint {
        id: bannerPaint
    }
    NumberAnimation {
        id: animateLeftListEnd
        target: idLeftListEnd
        properties: "opacity"
        from: 1
        to: 0
        loops: 1 //Animation.Infinite
        duration: 750
    }
    NumberAnimation {
        id: animateRightListEnd
        target: idRightListEnd
        properties: "opacity"
        from: 1
        to: 0
        loops: 1 //Animation.Infinite
        duration: 750
    }

    Rectangle {
        id: root
        //anchors.fill: parent
        width: isPortrait ? appWidth : appHeight // needed to not resize image when keyboard shows up
        height: isPortrait ? appHeight : appWidth // needed to not resize image when keyboard shows up
        color: "black" // background color prevents theme shining through for some milliseconds during rotation

        SilicaFlickable {
            id: flick
            anchors.fill: parent
            contentWidth: width
            contentHeight: height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            PinchArea {
                id: pinchArea
                width: Math.max(flick.contentWidth, flick.width)
                height: Math.max(flick.contentHeight, flick.height)
                enabled: pinchEnabled

                property real initialWidth_Pinch
                property real initialHeigth_Pinch

                onPinchStarted: {
                    stopSlideshow()
                    initialWidth_Pinch = flick.contentWidth
                    initialHeigth_Pinch = flick.contentHeight
                }
                onPinchUpdated: {
                    var newWidth = initialWidth_Pinch * pinch.scale
                    var newHeight = initialHeigth_Pinch * pinch.scale
                    if (newWidth < flick.width || newHeight < flick.height ) {
                        flick.resizeContent(flick.width, flick.height, Qt.point(flick.width/2, flick.height/2))
                    }
                    else {
                        flick.contentX += pinch.previousCenter.x - pinch.center.x
                        flick.contentY += pinch.previousCenter.y - pinch.center.y
                        flick.resizeContent(initialWidth_Pinch * pinch.scale, initialHeigth_Pinch * pinch.scale, pinch.center)
                    }
                }
                onPinchFinished: {
                    flick.returnToBounds()
                }

                Image {
                    id: idImageView
                    anchors.centerIn: parent
                    width: flick.contentWidth
                    height: flick.contentHeight
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    autoTransform: true
                    source: (reloadImage === false) ? currentImagePath : ""
                    cache: false
                    onStatusChanged: {
                        if (status === Image.Loading) {
                            finishedLoadingView = false
                        }
                        else if (status === Image.Ready) {
                            finishedLoadingView = true
                            firstTimeLoading = false
                            currentSlideshowImagePath = source
                        }
                    }

                    MouseArea {
                        id: idMouseAreaFlick
                        enabled: flickScale !== 1 && idImageView.status !== Image.Loading
                        hoverEnabled: true
                        anchors.fill: parent
                        onDoubleClicked: {
                            flick.contentWidth = flick.width
                            flick.contentHeight = flick.height
                            flick.contentX = 0
                            flick.contentY = 0
                            flick.returnToBounds()
                            // faster but gives strange animation
                            //flick.resizeContent(flick.contentWidth*1.5, flick.contentHeight*1.5, Qt.point(mouseX, mouseY))
                            //flick.resizeContent(flick.width, flick.height, Qt.point(flick.width/2, flick.height/2))
                        }
                    }
                    MouseArea {
                        id: idMouseAreaSwipe
                        enabled: flickScale === 1 && idImageView.status !== Image.Loading
                        anchors.fill: parent
                        anchors.topMargin: upperFreeHeight

                        property var position : {"x":0, "y":x}
                        property var limitMouseDistanceSwipe
                        /*
                        onPressAndHold: {
                            if (pillowAvailable) {
                                bannerTools.notify()
                            }
                        }
                        */
                        onEntered: {
                            stopSlideshow()
                            limitMouseDistanceSwipe = false
                            position.x = mouseX
                            position.y = mouseY
                        }
                        onMouseXChanged: {
                            if (limitMouseDistanceSwipe === false) {
                                if (mouseX - position.x > minMouseMoveXSwipeImage && Math.abs(mouseY - position.y) < minMouseMoveXSwipeImage) {
                                    //console.log(swipe right = go backwards")
                                    limitMouseDistanceSwipe = true
                                    if (currentImageIndex > 0) {
                                        currentImageIndex = currentImageIndex - 1
                                    }
                                    else {
                                        animateLeftListEnd.start()
                                    }
                                }
                                else if (position.x - mouseX > minMouseMoveXSwipeImage && Math.abs(mouseY - position.y) < minMouseMoveXSwipeImage) {
                                    //console.log(swipe left = go foreward")
                                    limitMouseDistanceSwipe = true
                                    if (currentImageIndex < allCurrentModelImagePathsArray.length-1) {
                                        currentImageIndex = currentImageIndex + 1
                                    }
                                    else {
                                        animateRightListEnd.start()
                                    }
                                }
                            }
                        }
                        onReleased: {
                            limitMouseDistanceSwipe = false
                        }
                    }


                }
                BrightnessContrast {
                    id: idImagePreviewColors
                    enabled: pillowAvailable && bannerColorize.opacity === 1
                    visible: enabled
                    anchors.fill: idImageView
                    source: idImageView
                    brightness: 0
                    contrast: 0
                }
            }
        }
        IconButton {
            id: idButtonClose
            anchors.left: parent.left
            visible: (flickScale === 1) && (bannerCrop.opacity === 0) && (bannerColorize.opacity === 0) && (bannerResize.opacity === 0) && (bannerTools.opacity === 0) && (bannerPaint.opacity === 0)
            height: upperFreeHeight
            width: height
            icon.scale: 1
            icon.source: "image://theme/icon-m-cancel?"
            onClicked: {
                stopSlideshow()
                //viewpageActiveFocus = false
                pageStack.pop()
            }

            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width / 3*2
                height: width
                radius: width/2
                color: Theme.rgba(Theme.highlightDimmerColor, 0.5)
            }
        }
        IconButton {
            id: idButtonSlideshow
            anchors {
                horizontalCenter: isPortrait ? parent.horizontalCenter : parent.left
                horizontalCenterOffset: isPortrait ? 0 : width/2
                verticalCenter: isPortrait ? parent.top : parent.verticalCenter
                verticalCenterOffset: isPortrait ? height/2 : 0
            }
            visible: (pillowAvailable) && (flickScale === 1) && (bannerCrop.opacity === 0) && (bannerColorize.opacity === 0) && (bannerResize.opacity === 0) && (bannerTools.opacity === 0) && (bannerPaint.opacity === 0)
            height: upperFreeHeight
            width: height
            //icon.scale: 1.9
            icon.source: runSlideshowTimer ? ("image://theme/icon-cover-pause?") : ("image://theme/icon-cover-play?")
            onClicked: {
                if (currentImageIndex < allCurrentModelImagePathsArray.length-1) {
                    runSlideshowTimer ? runSlideshowTimer = false : runSlideshowTimer = true
                }
                else {
                    animateRightListEnd.start()
                }
            }

            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width / 3*2
                height: width
                radius: width/2
                color: Theme.rgba(Theme.highlightDimmerColor, 0.5)
            }
            ProgressCircle {
                id: idProgressCircle
                scale: 0.85
                visible: runSlideshowTimer
                anchors.fill: parent
                backgroundColor: "transparent" //Theme.darkPrimaryColor
                progressColor: Theme.secondaryHighlightColor
                inAlternateCycle: false
                value: 1-slideshowTimerProgress
            }
        }
        IconButton {
            id: idButtonEdit
            anchors.right: isPortrait ? parent.right : parent.left
            anchors.rightMargin: isPortrait ? 0 : -width
            anchors.top: isPortrait ? parent.top : parent.bottom
            anchors.topMargin: isPortrait ? 0 : -height
            visible: (pillowAvailable) && (flickScale === 1) && (bannerCrop.opacity === 0) && (bannerColorize.opacity === 0) && (bannerResize.opacity === 0) && (bannerTools.opacity === 0) && (bannerPaint.opacity === 0)
            height: upperFreeHeight
            width: height
            icon.scale: 1
            icon.source: "image://theme/icon-m-edit?"
            onClicked: {
                stopSlideshow()
                if (pillowAvailable) {
                    bannerTools.notify()
                }
            }

            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width / 3*2
                height: width
                radius: width/2
                color: Theme.rgba(Theme.highlightDimmerColor, 0.5)
            }
        }

        Rectangle {
            id: idLeftListEnd
            opacity: 0
            y: Theme.itemSizeLarge
            width: Theme.paddingSmall
            height: parent.height - 2*y
            color: Theme.errorColor
        }
        Rectangle {
            id: idRightListEnd
            opacity: 0
            y: Theme.itemSizeLarge
            width: Theme.paddingSmall
            height: parent.height - 2*y
            color: Theme.errorColor
            anchors.right: parent.right
        }
        BusyIndicator {
            anchors.centerIn: parent
            running: finishedLoadingView === false
            size: BusyIndicatorSize.Large
        }
    }


    function freezeOrientation() {
        if (isPortrait === true) {
            allowedOrientations = Orientation.PortraitMask
        }
        else {
            allowedOrientations = Orientation.LandscapeMask
        }
    }

    function stopSlideshow() {
        slideshowTimerProgress = 100
        runSlideshowTimer = false
    }

    function resetCountdownTimer(){
        slideshowTimerProgress = 0
        var startDateMS = (new Date()).getTime()
        targetDateMS = startDateMS + coverImageChangeInterval
    }
}
