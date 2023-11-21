import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupResize
    z: 10
    width: parent.width
    height: parent.height
    opacity: 0.0
    visible: opacity > 0
    onClicked: {
        hide()
    }

    property var startW
    property var startH
    property var imagePaths
    property string targetDimension : "width"


    Behavior on opacity {
        //FadeAnimator {}
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
            width: Theme.itemSizeLarge * 3.5
            height: idImageResizeColumn.height
            radius: Theme.paddingLarge
            color: buttonBackgroundColor
            border.width: 2
            border.color: Theme.highlightColor

            Column {
                id: idImageResizeColumn
                width: parent.width
                spacing: Theme.paddingSmall

                Item {
                    visible: (imagePaths === "single" || targetDimension === "width")
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width / 3 * 2
                    height: Theme.itemSizeLarge

                    TextField {
                        id: idTextFieldNewWidth
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        label: qsTr("width")
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 9999 }
                        onClicked: {
                            //
                        }
                        EnterKey.onClicked: {
                            if (text.length > 0) {
                                if (imagePaths === "single") {
                                    idTextFieldNewHeight.text = parseInt( parseInt(text) / startW * parseInt(startH) )
                                }
                                focus = false
                            }
                        }
                    }
                }
                Item {
                    visible: (imagePaths === "single" || targetDimension === "height")
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width / 3 * 2
                    height: Theme.itemSizeLarge

                    TextField {
                        id: idTextFieldNewHeight
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        label: qsTr("height")
                        inputMethodHints: Qt.ImhDigitsOnly
                        validator: IntValidator { bottom: 1; top: 9999 }
                        onClicked: {
                            //
                        }
                        EnterKey.onClicked: {
                            if (text.length > 0) {
                                if (imagePaths === "single") {
                                    idTextFieldNewWidth.text = parseInt( parseInt(text) / startH * parseInt(startW) )
                                }
                                focus = false
                            }
                        }
                    }
                }
                IconButton {
                    visible: imagePaths !== "single"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width / 3 * 2
                    height: Theme.iconSizeLarge
                    icon.source: "image://theme/icon-m-rotate?"
                    rotation: (targetDimension === "width") ? 0 : 90
                    onClicked: {
                        (targetDimension === "width") ? targetDimension = "height" : targetDimension = "width"
                    }
                }
            }
            IconButton {
                anchors.verticalCenter: idImageResizeColumn.verticalCenter
                anchors.horizontalCenter: idImageResizeColumn.left
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
                anchors.verticalCenter: idImageResizeColumn.verticalCenter
                anchors.horizontalCenter: idImageResizeColumn.right
                enabled: (idTextFieldNewWidth.focus === false) && (idTextFieldNewHeight.focus === false)
                height: Theme.itemSizeLarge * 1.1
                width: height
                icon.scale: 1
                icon.source: "image://theme/icon-m-accept?"
                onClicked: {
                    var targetWidth = Math.round(idTextFieldNewWidth.text, 0)
                    var targetHeight = Math.round(idTextFieldNewHeight.text, 0)
                    if (imagePaths === "single") {
                        finishedLoadingView = false
                        py.imageResizeFunction( currentImagePath, targetWidth, targetHeight )
                    }
                    else { // bulk resizing
                        if (targetDimension === "width") {
                            var targetDirection = "preferWidth"
                        }
                        else { // targetDimension === "height"
                            targetDirection = "preferHeight"
                        }
                        py.imageBulkResizeFunction( imagePaths, targetWidth, targetHeight, targetDirection )
                    }
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
    }


    function notify( startWidth, startHeight, imagePathsList ) {
        popupResize.opacity = 1.0
        if (imagePathsList === "single") {
            pinchEnabled = false
            mainBackgroundRect.color = "transparent"
        }
        startW = startWidth
        startH = startHeight
        imagePaths = imagePathsList // "single" or batch files list, defines which python function will be called finally
        targetDimension = "width"
        idTextFieldNewWidth.text = startWidth
        idTextFieldNewHeight.text = startHeight
    }

    function hide() {
        idTextFieldNewWidth.focus = false
        idTextFieldNewHeight.focus = false
        popupResize.opacity = 0.0
        if (imagePaths === "single") { // this should only be the case on viewPage
            pinchEnabled = true
            allowedOrientations = Orientation.All
        }
        else { // on albumPage, where multiple images could be selected still
            unselectAll()
        }
    }
}
