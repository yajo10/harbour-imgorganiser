import QtQuick 2.6
import Sailfish.Silica 1.0


CoverBackground {
    id: cover
    onStatusChanged: {
        if (cover.status === Cover.Active) {
            //console.log("active cover")
            coverpageActiveFocus = true
        }
        else if (cover.status === Cover.Inactive) {
            //console.log("inactive cover")
            coverpageActiveFocus = false
        }
    }

    Image {
        id: idCoverStandard
        visible: !idCoverSlideshow.visible
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -idRectangleBottom.height / 2
        source: "harbour-timeline.svg"
        width: Theme.iconSizeLarge
        height: Theme.iconSizeLarge
        sourceSize.width: width
        sourceSize.height: height
        fillMode: Image.PreserveAspectFit
    }
    Image {
        id: idCoverSlideshow
        visible: infoActivateCoverImages !== 0 && finishedLoading
        enabled: visible
        anchors.fill: parent
        sourceSize.width: sourceSize.width
        sourceSize.height: sourceSize.height
        smooth: true
        autoTransform: true
        fillMode: Image.PreserveAspectCrop
        source: (viewpageActiveFocus) ? (currentSlideshowImagePath) : (runSlideshowTimer && currentSlideshowImagePath !== undefined) ? (currentSlideshowImagePath) : (coverImagePath)
        onSourceChanged: {
            opacityCoverImage.start()
        }
    }
    Image {
        visible: infoActivateCoverImages !== 0 && finishedLoading
        enabled: visible
        anchors.fill: parent
        sourceSize.width: sourceSize.width
        sourceSize.height: sourceSize.height
        smooth: true
        autoTransform: true
        fillMode: Image.PreserveAspectCrop
        onOpacityChanged:
            if (opacity === 0) {
                source = idCoverSlideshow.source
                opacity = 1
            }
        NumberAnimation on opacity {
            id: opacityCoverImage
            from: 1
            to: 0
            duration: 1000
        }
    }

    Rectangle {
        id: idRectangleBottom
        anchors.bottom: parent.bottom
        width: parent.width * currentlyScannedImage / maxScannedImages
        height: Theme.itemSizeSmall
        color: Theme.rgba(Theme.highlightDimmerColor, 0.5)
    }
    Label {
        anchors.bottom: parent.bottom
        width: parent.width
        height: Theme.itemSizeSmall
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        truncationMode: TruncationMode.Elide
        text: ("ImgOrganizer")
    }
    /*
    CoverActionList {
        id: coverAction

        CoverAction {
            iconSource: "image://theme/icon-cover-next"
        }

        CoverAction {
            iconSource: "image://theme/icon-cover-pause"
        }
    }
    */
}
