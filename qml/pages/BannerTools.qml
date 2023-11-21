import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupTools
    z: 10
    width: parent.width
    height: parent.height
    opacity: 0.0
    visible: opacity > 0
    onClicked: {
        hide( "close" )
    }

    RemorsePopup {
        height: Theme.itemSizeLarge * 1.3
        id: remorse
    }
    Behavior on opacity {
        //FadeAnimator {}
    }
    Grid {
        id: idBackgroundRectTools
        anchors.bottom: parent.bottom
        anchors.bottomMargin: upperFreeHeight
        anchors.horizontalCenter: parent.horizontalCenter
        columns: (isPortrait === true) ? 3 : 5
        spacing: Theme.paddingSmall

        IconButton {
            id: idButtonRotateLeft
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-rotate-left?"
            icon.scale: 1
            onClicked: {
                finishedLoadingView = false
                py.imageRotateFunction(currentImagePath, 90)
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
            id: idButtonRotateRight
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-rotate-right?"
            icon.scale: 1
            onClicked: {
                finishedLoadingView = false
                py.imageRotateFunction(currentImagePath, 270)
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
            id: idButtonCrop
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-crop?"
            icon.scale: 1
            onClicked: {
                freezeOrientation() // needed to not get the cropping handles confused when orientation changes
                bannerCrop.notify( )
                hide( "locked" )
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
            id: idButtonFlip
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-flip?"
            icon.scale: 1
            icon.rotation: 90
            onClicked: {
                finishedLoadingView = false
                py.imageFlipMirrorFunction(currentImagePath, "vertical")
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
            id: idButtonMirror
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-flip?"
            icon.scale: 1
            onClicked: {
                finishedLoadingView = false
                py.imageFlipMirrorFunction(currentImagePath, "horizontal")
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
            id: idButtonColor
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-light-contrast?"
            icon.scale: 1
            onClicked: {
                freezeOrientation()
                bannerColorize.notify( )
                hide("locked")
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
            id: idButtonResize
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-scale?"
            icon.scale: 1
            onClicked: {
                freezeOrientation()
                bannerResize.notify( idImageView.sourceSize.width, idImageView.sourceSize.height, "single" )
                hide("locked")
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
            id: idButtonDelete
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-delete?"
            icon.scale: 1

            function removeFile( filePathArray ) {
                remorse.execute(qsTr("Delete file?"), function() {
                    deleteThisImage( filePathArray, "viewPage" )
                    pageStack.pop() // close the previous view
                })
            }

            onClicked: {
                hide("locked") // hide toolbar
                var chosenFilesArray = []
                chosenFilesArray.push(currentImagePath)
                removeFile( chosenFilesArray )
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
            id: idButtonPaint
            width: Theme.itemSizeLarge * 1.1
            height: width
            icon.source: "image://theme/icon-m-edit?"
            icon.scale: 1
            onClicked: {
                freezeOrientation()
                bannerPaint.notify( currentImagePath, imageRatioSourceScreen )
                hide("locked") // hide toolbar
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


    function notify() {
        popupTools.opacity = 1.0
        pinchEnabled = false
    }

    function hide( command ) {
        popupTools.opacity = 0.0
        if (command !== "locked") {
            pinchEnabled = true
            allowedOrientations = Orientation.All
        }
    }
}
