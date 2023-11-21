import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Silica.private 1.0 // library, disable system gestures

MouseArea {
    id: popupCrop
    z: 10
    width: parent.width
    height: parent.height
    opacity: 0.0
    visible: opacity > 0
    onClicked: {
        hide()
    }

    // UI variables
    property real cropHandleSize : Theme.iconSizeMedium * 1.15 // Theme.paddingLarge * 2.5
    property color cropHandleColor : Theme.rgba(Theme.highlightColor, 1) // Theme.errorColor
    property real cropHandleOpacity : 0.75
    property real imageScaleFactorDisplay

    // handles swipe variable
    property bool hideButtons : false
    property real croppingFixedRatio : 0
    property real oldPosX1
    property real oldPosY1
    property real diffX1
    property real diffY1
    property real stopX1
    property real oldPosX2
    property real oldPosY2
    property real diffX2
    property real diffY2
    property real stopX2

    // resulting rectangle swipe variables
    property real oldmouseX
    property real oldmouseY
    property real oldWidth
    property real oldHeight
    property real oldFullAreaHeight
    property real oldFullAreaWidth
    property string oldWhichSquareLEFT
    property string oldWhichSquareUP


    Behavior on opacity {
        //FadeAnimator {}
    }
    WindowGestureOverride { // disable system gestures
        id: idGestureOverride
        active: parent.opacity > 0
    }
    Item {
        id: backgroundRect
        anchors.centerIn: parent

        Item {
            id: idItemCropzoneHandles
            anchors.fill: parent

            // Handles defining corners of a rectangle to crop
            Rectangle {
                id: rectDrag1
                radius: Theme.paddingSmall / 2
                width: cropHandleSize
                height: width
                color: cropHandleColor
                opacity: cropHandleOpacity

                MouseArea {
                    id: dragArea1
                    preventStealing: true // Patch: crop by coordinates disables moving...
                    anchors.fill: parent
                    drag.target: parent
                    drag.minimumX: (0)
                    drag.maximumX: (idItemCropzoneHandles.width - cropHandleSize)
                    drag.minimumY: (idItemCropzoneHandles.y)
                    drag.maximumY: (idItemCropzoneHandles.height - cropHandleSize)
                    onEntered: {
                        oldPosX1 = rectDrag1.x
                        oldPosY1 = rectDrag1.y
                        hideButtons = true
                    }
                    onPositionChanged: {
                        if (croppingFixedRatio != 0) {
                            diffX1 = rectDrag1.x - oldPosX1
                            diffY1 = (diffX1 / croppingFixedRatio)
                            rectDrag1.y = oldPosY1 + diffY1
                            if (rectDrag1.y > (idItemCropzoneHandles.height - cropHandleSize)) {
                                rectDrag1.y = idItemCropzoneHandles.height - cropHandleSize
                                rectDrag1.x = stopX1
                            }
                            else if (rectDrag1.y < 0) {
                                rectDrag1.y = 0
                                rectDrag1.x = stopX1
                            }
                            else {
                                stopX1 = rectDrag1.x
                            }
                        }
                        //calculateZoomImagePart(rectDrag1)
                    }
                    onReleased: {
                        hideButtons = false
                    }
                }
            }
            Rectangle {
                id: rectDrag2
                radius: Theme.paddingSmall / 2
                width: cropHandleSize
                height: width
                color: cropHandleColor
                opacity: cropHandleOpacity

                MouseArea {
                    id: dragArea2
                    preventStealing: true
                    // Patch: crop by coordinates disables moving...
                    anchors.fill: parent
                    drag.target: parent
                    drag.minimumX: (0) //idItemCropzoneHandles.x
                    drag.maximumX: (idItemCropzoneHandles.width - cropHandleSize)
                    drag.minimumY: (idItemCropzoneHandles.y)
                    drag.maximumY: (idItemCropzoneHandles.height - cropHandleSize)
                    onEntered: {
                        oldPosX2 = rectDrag2.x
                        oldPosY2 = rectDrag2.y
                        hideButtons = true
                    }
                    onPositionChanged: {
                        if (croppingFixedRatio != 0) {
                            diffX2 = rectDrag2.x - oldPosX2
                            diffY2 = (diffX2 / croppingFixedRatio)
                            rectDrag2.y = oldPosY2 + diffY2
                            if (rectDrag2.y > (idItemCropzoneHandles.height - cropHandleSize)) {
                                rectDrag2.y = idItemCropzoneHandles.height - cropHandleSize
                                rectDrag2.x = stopX2
                            }
                            else if (rectDrag2.y < 0) {
                                rectDrag2.y = 0
                                rectDrag2.x = stopX2
                            }
                            else {
                                stopX2 = rectDrag2.x
                            }
                        }
                        //calculateZoomImagePart(rectDrag2)
                    }
                    onReleased: {
                        hideButtons = false
                    }
                }
            }

            // Resulting rectangle, contains cropped part of image
            Rectangle {
                id: frameRectangleCroppingzone
                z: -1
                color: "transparent"
                anchors.top: (rectDrag1.y < rectDrag2.y) ? rectDrag1.top : rectDrag2.top
                anchors.left: (rectDrag1.x < rectDrag2.x) ? rectDrag1.left : rectDrag2.left
                anchors.bottom: ((rectDrag1.y + rectDrag1.height) > (rectDrag2.y + rectDrag2.height)) ? rectDrag1.bottom : rectDrag2.bottom
                anchors.right: ((rectDrag1.x + rectDrag1.width) > (rectDrag2.x + rectDrag2.width)) ? rectDrag1.right : rectDrag2.right

                MouseArea {
                    id: dragAreaFullCroppingZone
                    // Patch: crop by coordinates disables moving...
                    anchors.fill: parent
                    drag.target:  parent
                    onEntered: {
                        oldmouseX = mouseX
                        oldmouseY = mouseY
                        oldWidth = parent.width
                        oldHeight = parent.height
                        oldFullAreaWidth = idItemCropzoneHandles.width
                        oldFullAreaHeight = idItemCropzoneHandles.height
                        if (rectDrag1.x < rectDrag2.x) { oldWhichSquareLEFT = "left1" }
                            else { oldWhichSquareLEFT = "left2" }
                        if (rectDrag1.y < rectDrag2.y) { oldWhichSquareUP = "up1" }
                            else { oldWhichSquareUP = "up2" }
                        hideButtons = true
                    }
                    onMouseXChanged: {
                        rectDrag1.x = rectDrag1.x + (mouseX - oldmouseX)
                        rectDrag2.x = rectDrag2.x + (mouseX - oldmouseX)
                        if (oldWhichSquareLEFT === "left1") {
                            if (rectDrag1.x < 0) {
                                rectDrag1.x = 0
                                rectDrag2.x = oldWidth - rectDrag1.width
                            }
                            if ((rectDrag2.x+rectDrag2.width) > oldFullAreaWidth) {
                                rectDrag2.x = oldFullAreaWidth - rectDrag2.width
                                rectDrag1.x = oldFullAreaWidth - oldWidth
                            }
                        }
                        if (oldWhichSquareLEFT === "left2") {
                            if (rectDrag2.x < 0) {
                                rectDrag2.x = 0
                                rectDrag1.x = oldWidth - rectDrag2.width
                            }
                            if ((rectDrag1.x+rectDrag1.width) > oldFullAreaWidth) {
                                rectDrag1.x = oldFullAreaWidth - rectDrag1.width
                                rectDrag2.x = oldFullAreaWidth - oldWidth
                            }
                        }
                    }
                    onMouseYChanged: {
                        rectDrag1.y = rectDrag1.y + (mouseY - oldmouseY)
                        rectDrag2.y = rectDrag2.y + (mouseY - oldmouseY)
                        if (oldWhichSquareUP === "up1") {
                            if (rectDrag1.y < 0) {
                                rectDrag1.y = 0
                                rectDrag2.y = oldHeight - rectDrag1.height
                            }
                            if ((rectDrag2.y+rectDrag2.height) > oldFullAreaHeight) {
                                rectDrag2.y = oldFullAreaHeight - rectDrag2.height
                                rectDrag1.y = oldFullAreaHeight - oldHeight
                            }
                        }
                        if (oldWhichSquareUP === "up2") {
                            if (rectDrag2.y < 0) {
                                rectDrag2.y = 0
                                rectDrag1.y = oldHeight - rectDrag2.height
                            }
                            if ((rectDrag1.y+rectDrag1.height) > oldFullAreaHeight) {
                            rectDrag1.y = oldFullAreaHeight - rectDrag1.height
                            rectDrag2.y = oldFullAreaHeight - oldHeight
                            }
                        }
                    }
                    onReleased: {
                        hideButtons = false
                    }
                }
            }
            Rectangle {
                z: 4
                anchors.fill: frameRectangleCroppingzone
                radius: Theme.paddingSmall / 2
                color: "transparent"
                border.color: Theme.rgba(Theme.highlightColor, 0.5) //Theme.errorColor
                border.width: 2
            }

            // The gray zones to cut away
            Rectangle {
                id: grayzoneUP
                anchors.top: parent.top
                anchors.left: parent.left
                width: idItemCropzoneHandles.width
                height: Math.min(rectDrag1.y, rectDrag2.y)
                color: "black"
                opacity: 0.75
            }
            Rectangle {
                id: grayzoneLEFT
                anchors.left: parent.left
                y: Math.min(rectDrag1.y, rectDrag2.y)
                width: Math.min(rectDrag1.x, rectDrag2.x)
                height: Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                color: "black"
                opacity: 0.75
            }
            Rectangle {
                id: grayzoneDOWN
                anchors.left: parent.left
                y: Math.max((rectDrag1.y + rectDrag1.height), (rectDrag2.y + rectDrag2.height))
                width: idItemCropzoneHandles.width + Theme.paddingSmall / 2
                height: idItemCropzoneHandles.height - Math.max(rectDrag1.y + rectDrag1.height, rectDrag2.y + rectDrag2.height) + Theme.paddingSmall / 2
                color: "black"
                opacity: 0.75
            }
            Rectangle {
                id: grayzoneRIGHT
                x: Math.max(rectDrag1.x + rectDrag1.width, rectDrag2.x + rectDrag2.width)
                y: Math.min(rectDrag1.y, rectDrag2.y)
                width: idItemCropzoneHandles.width - Math.max(rectDrag1.x + rectDrag1.width, rectDrag2.x + rectDrag2.width) + Theme.paddingSmall / 2
                height: Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                color: "black"
                opacity: 0.75
            }

            // Optical deviders into thirds
            Rectangle {
                id: grayVerticalDevider1
                x: Math.min(rectDrag1.x, rectDrag2.x) + (Math.max(rectDrag2.x+rectDrag2.width, rectDrag1.x+rectDrag1.width) - Math.min(rectDrag1.x, rectDrag2.x))/3
                y: Math.min(rectDrag1.y, rectDrag2.y)
                z: -1
                width: 1
                height: Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                color: "black"
                opacity: 0.75
            }
            Rectangle {
                id: grayVerticalDevider2
                x: Math.min(rectDrag1.x, rectDrag2.x) + (Math.max(rectDrag2.x+rectDrag2.width, rectDrag1.x+rectDrag1.width) - Math.min(rectDrag1.x, rectDrag2.x))/3*2
                y: Math.min(rectDrag1.y, rectDrag2.y)
                z: -1
                width: 1
                height: Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                color: "black"
                opacity: 0.75
            }
            Rectangle {
                id: grayHorizontalDevider1
                x: Math.min(rectDrag1.x, rectDrag2.x)
                y: Math.min(rectDrag1.y, rectDrag2.y) + (Math.max(rectDrag2.y+rectDrag2.height, rectDrag1.y+rectDrag1.height) - Math.min(rectDrag1.y, rectDrag2.y))/3
                z: -1
                width: Math.max(rectDrag1.x+rectDrag1.width, rectDrag2.x+rectDrag2.width) - Math.min(rectDrag1.x, rectDrag2.x)
                height: 1
                color: "black"
                opacity: 0.75
            }
            Rectangle {
                id: grayHorizontalDevider2
                x: Math.min(rectDrag1.x, rectDrag2.x)
                y: Math.min(rectDrag1.y, rectDrag2.y) + (Math.max(rectDrag2.y+rectDrag2.height, rectDrag1.y+rectDrag1.height) - Math.min(rectDrag1.y, rectDrag2.y))/3*2
                z: -1
                width: Math.max(rectDrag1.x+rectDrag1.width, rectDrag2.x+rectDrag2.width) - Math.min(rectDrag1.x, rectDrag2.x)
                height: 1
                color: "black"
                opacity: 0.75
            }
        }
    }
    Rectangle {
        id: idBackgroundRectCrop
        z:10
        visible: (hideButtons === false)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: upperFreeHeight
        width: Theme.itemSizeLarge * 3.5
        height: Theme.iconSizeLarge
        radius: height/2 //Theme.paddingLarge
        color: buttonBackgroundColor
        border.width: 2
        border.color: Theme.highlightColor

        ComboBox {
            id: idComboBoxCropRatio
            width: parent.width - Theme.itemSizeLarge
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("free crop")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 0
                        setCropmarkersFullImage()
                    }
                }
                MenuItem {
                    text: qsTr("original")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = (idItemCropzoneHandles.width - cropHandleSize) / (idItemCropzoneHandles.height - cropHandleSize)
                        setCropmarkersFullImage()
                    }
                }
                MenuItem {
                    text: qsTr("DIN-landscape")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 1754/1240
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("4:3")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 4/3
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("16:10")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 16/10
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("16:9")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 16/9
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("2:1")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 2/1
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("21:9")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 21/9
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("1:1")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 1
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("9:21")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 9/21
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("1:2")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 1/2
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("9:16")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 9/16
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("10:16")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 10/16
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: ("3:4")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 3/4
                        setCropmarkersRatio()
                    }
                }
                MenuItem {
                    text: qsTr("DIN-portrait")
                    font.pixelSize: Theme.fontSizeExtraSmall
                    onClicked: {
                        croppingFixedRatio = 1240/1754
                        setCropmarkersRatio()
                    }
                }
            }
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.left
            height: Theme.itemSizeLarge * 1.1
            width: height
            icon.scale: 1
            icon.source: "image://theme/icon-m-cancel?"
            onClicked: {
                hide()
            }
            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width / 5*4
                height: width
                radius: width/2
                color: buttonBackgroundColor
                border.width: 2
                border.color: Theme.highlightColor
            }
        }
        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.right
            height: Theme.itemSizeLarge * 1.1
            width: height
            icon.scale: 1
            icon.source: "image://theme/icon-m-accept?"
            onClicked: {
                finishedLoadingView = false
                var rectX = Math.min(rectDrag1.x, rectDrag2.x)
                var rectY = Math.min(rectDrag1.y, rectDrag2.y)
                var rectWidth = Math.max(rectDrag1.x+rectDrag1.width, rectDrag2.x+rectDrag2.width) - Math.min(rectDrag1.x, rectDrag2.x)
                var rectHeight = Math.max(rectDrag1.y+rectDrag1.height, rectDrag2.y+rectDrag2.height) - Math.min(rectDrag1.y, rectDrag2.y)
                py.imageCropFunction( currentImagePath, rectX, rectY, rectWidth, rectHeight, imageScaleFactorDisplay )
                hide()
            }
            Rectangle {
                z: -1
                anchors.centerIn: parent
                width: parent.width / 5*4
                height: width
                radius: width/2
                color: buttonBackgroundColor
                border.width: 2
                border.color: Theme.highlightColor
            }
        }
    }


    function setCropmarkersFullImage() {
        rectDrag1.x = 0
        rectDrag1.y = 0
        rectDrag2.x = idItemCropzoneHandles.width - cropHandleSize
        rectDrag2.y = idItemCropzoneHandles.height - cropHandleSize
    }

    function setCropmarkersRatio() {
            rectDrag1.x = 0
            rectDrag1.y = 0
            idItemCropzoneHandles.width = backgroundRect.width
            idItemCropzoneHandles.height = backgroundRect.height

            // check how the cropping zone in the image, to define which value touches the border first: x or y?
            if ( croppingFixedRatio <= (imageSourceWidth / imageSourceHeight) ) {
                rectDrag2.y = idItemCropzoneHandles.height - cropHandleSize
                // Patch: takes into account handle disposition
                var correctionFactorY = cropHandleSize - (cropHandleSize * croppingFixedRatio)
                rectDrag2.x = rectDrag2.y * croppingFixedRatio - correctionFactorY
            }
            else {
                rectDrag2.x = idItemCropzoneHandles.width - cropHandleSize
                // Patch: takes into account handle disposition
                var correctionFactorX = cropHandleSize - (cropHandleSize / croppingFixedRatio)
                rectDrag2.y = rectDrag2.x / croppingFixedRatio - correctionFactorX
            }

            // place cropping zone in vertical center
            var diffMarkerRatiosY = (idItemCropzoneHandles.height - (rectDrag2.y + rectDrag2.height))
            if ((rectDrag2.y + diffMarkerRatiosY/2) <= idItemCropzoneHandles.height) {
                rectDrag1.y = rectDrag1.y + diffMarkerRatiosY/2
                rectDrag2.y = rectDrag2.y + diffMarkerRatiosY/2
            }
            else {
                rectDrag1.x = 0
                rectDrag1.y = 0
                rectDrag2.y = idItemCropzoneHandles.height - cropHandleSize
                rectDrag2.x = rectDrag2.y * croppingFixedRatio
                var diffMarkerRatiosX2 = (idItemCropzoneHandles.width - (rectDrag2.x + rectDrag2.width))
                rectDrag1.x = rectDrag1.x + diffMarkerRatiosX2/2
                rectDrag2.x = rectDrag2.x + diffMarkerRatiosX2/2
            }

            // place cropping zone in horizontal center
            var diffMarkerRatiosX = (idItemCropzoneHandles.width - (rectDrag2.x + rectDrag2.width))
            if ((rectDrag1.x + diffMarkerRatiosX/2) >= 0) {
                rectDrag1.x = rectDrag1.x + diffMarkerRatiosX/2
                rectDrag2.x = rectDrag2.x + diffMarkerRatiosX/2
            }
            else {
                rectDrag1.x = 0
                rectDrag1.y = 0
                rectDrag2.x = idItemCropzoneHandles.width - cropHandleSize
                rectDrag2.y = rectDrag2.x / croppingFixedRatio
                var diffMarkerRatiosY1 = (idItemCropzoneHandles.height - (rectDrag2.y + rectDrag2.height))
                rectDrag1.y = rectDrag1.y + diffMarkerRatiosY1/2
                rectDrag2.y = rectDrag2.y + diffMarkerRatiosY1/2
            }

        }

    function notify() {
        popupCrop.opacity = 1.0
        backgroundRect.width = imagePaintedWidth
        backgroundRect.height = imagePaintedHeight
        pinchEnabled = false

        // set scale factor=1 if image pixels match screen pixels
        imageScaleFactorDisplay = imageSourceWidth / imagePaintedWidth

        // set handles to image max
        setCropmarkersFullImage()
        croppingFixedRatio = 0
        idComboBoxCropRatio.currentIndex = 0
    }

    function hide() {
        popupCrop.opacity = 0.0
        pinchEnabled = true
        allowedOrientations = Orientation.All
    }


}
