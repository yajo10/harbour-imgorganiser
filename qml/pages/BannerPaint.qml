import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupPaint
    z: 10
    width: parent.width
    height: parent.height
    opacity: 0.0
    visible: opacity > 0
    onClicked: {
        //hide() // better to have it available when drawing, otherwise gets closed too often
    }

    // drawing variables
    property bool hideButtons : false
    property var freeDrawXpos
    property var freeDrawYpos
    property var filePath
    property var ratioSourceScreenImage
    property color lineColor : "white"
    property real lineWidth : Theme.paddingSmall
    property var myColors: [
        "#e60003", "#e6007c", "#e700cc",
        "#9d00e7", "#7b00e6", "#5d00e5",
        "#0077e7", "#01a9e7", "#00cce7",
        "#00e696", "#00e600", "#99e600",
        "#e3e601", "#e5bc00", "#e78601",
        "maroon", Theme.highlightDimmerColor, "black",
        "darkGray", "silver", "white",
    ]

    // undo variables
    property string freeDrawPolyCoordinatesTemp : ""
    property var freeDrawPolyCoordinatesArray : []
    property var imageData : []
    property int cStep : -1
    property var lineColorArray : []
    property var lineWidthArray : []


    Behavior on opacity {
        //FadeAnimator {}
    }
    Component {
        id: colorPickerPage
        ColorPickerPage {
            width: 300
            height: 300
            colors: myColors
            onColorChanged: {
                lineColor = color
                pageStack.pop()
            }
        }
    }
    Timer {
        id: idRefreshCanvastimer
        running: false
        repeat: false
        interval: 10
        onTriggered: {
            freeDrawCanvas.visible = true
        }
    }

    Rectangle {
        id: mainBackgroundRect
        anchors.fill: parent
        color: hideBackColor

        Item {
            id: canvasFreeDrawing
            anchors.centerIn: parent

            Rectangle {
                width: parent.width
                height: parent.height
                color: "transparent"

                Canvas {
                    id: freeDrawCanvas
                    anchors.fill: parent
                    smooth: true
                    renderTarget: Canvas.FramebufferObject // default slower: Canvas.Image
                    renderStrategy: Canvas.Immediate // less memory: Canvas.Cooperative
                    onPaint: {
                        var ctx = getContext('2d')
                        ctx.beginPath()
                        ctx.lineCap = 'round'
                        ctx.strokeStyle = lineColor
                        ctx.lineWidth = lineWidth
                        ctx.moveTo(freeDrawXpos, freeDrawYpos)
                        ctx.lineTo(mouseCanvasArea.mouseX, mouseCanvasArea.mouseY)
                        ctx.stroke()
                        ctx.closePath()
                        freeDrawXpos = mouseCanvasArea.mouseX
                        freeDrawYpos = mouseCanvasArea.mouseY
                    }

                    function clear_canvas() {
                        var ctx = getContext("2d")
                        ctx.reset()
                        freeDrawCanvas.requestPaint()
                    }

                    function undoLastStroke () {
                        if (cStep >= 0) {
                            // remove the latest entries of coordinates from array, lineColorArray and lineWidthArray
                            freeDrawPolyCoordinatesArray.pop() //.slice(0,-1)
                            lineColorArray.pop() //.slice(0,-1)
                            lineWidthArray.pop() //.slice(0,-1)

                            // redraw the canvas
                            cStep--
                            var ctx = getContext('2d')
                            ctx.clearRect( 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
                            if ( (cStep+1) > 0) {
                                ctx.drawImage( imageData[cStep+1], 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
                            }
                            freeDrawCanvas.requestPaint()
                            freeDrawCanvas.visible = false
                            idRefreshCanvastimer.start() // needs to reload canvas, to show clear screen
                        }
                    }

                    function saveCurrentCanvas() {
                        cStep++
                        var ctx = getContext('2d')
                        imageData[cStep+1] = ctx.getImageData( 0, 0, freeDrawCanvas.width, freeDrawCanvas.height )
                    }

                    MouseArea {
                        id: mouseCanvasArea
                        preventStealing: true
                        anchors.fill: parent
                        onEntered: {
                            freeDrawXpos = mouseX
                            freeDrawYpos = mouseY
                            hideButtons = true
                            freeDrawPolyCoordinatesTemp = ""
                        }
                        onPositionChanged: {
                            freeDrawCanvas.requestPaint()
                            freeDrawPolyCoordinatesTemp += freeDrawXpos + ";" + freeDrawYpos + ";"
                        }
                        onReleased: {
                            freeDrawPolyCoordinatesTemp += mouseX + ";" + mouseY + ";"
                            hideButtons = false
                            freeDrawCanvas.saveCurrentCanvas()
                            freeDrawPolyCoordinatesArray.push(freeDrawPolyCoordinatesTemp)
                            lineColorArray.push(lineColor.toString())
                            lineWidthArray.push(lineWidth)
                        }
                    }
                }
            }
        }
        Rectangle {
            id: idBackgroundRect
            visible: (hideButtons === false)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: upperFreeHeight
            width: Theme.itemSizeLarge * 3.5
            height: Theme.iconSizeLarge
            radius: Theme.paddingLarge
            color: buttonBackgroundColor
            border.width: 2
            border.color: Theme.highlightColor

            Item {
                id: idButtonLineWidth
                height: parent.height
                width: height
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width / 3 * 1 - width/2

                Rectangle {
                    anchors.centerIn: parent
                    width: lineWidth
                    height: parent.height / 5 * 3
                    radius: width/2
                }
                Label {
                    id: idLabelLineWidth
                    anchors.right: parent.right
                    anchors.rightMargin: parent.width / 8
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: parent.height / 10
                    text: "1"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (idLabelLineWidth.text === "1") {
                            idLabelLineWidth.text = "2"
                            lineWidth = Theme.paddingMedium
                        } else if (idLabelLineWidth.text === "2") {
                            idLabelLineWidth.text = "3"
                            lineWidth = Theme.paddingLarge
                        } else { // when lineWidth is already "3"
                            idLabelLineWidth.text = "1"
                            lineWidth = Theme.paddingSmall
                        }
                    }
                }
            }
            Item {
                id: idbuttonLineColor
                height: parent.height
                width: height
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width / 3 * 2 - width/2

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width / 5 * 3
                    height: parent.height / 5 * 3
                    color: lineColor
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: pageStack.push(colorPickerPage)
                }
            }
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.left
                height: Theme.itemSizeLarge * 1.1
                width: height
                icon.scale: (cStep < 0) ? 1 : 2
                icon.source: (cStep < 0) ? ("image://theme/icon-m-cancel?") : ("../symbols/icon-m-step-back.svg")
                onClicked: {
                    if (cStep < 0) {
                        hide()
                    } else {
                        freeDrawCanvas.undoLastStroke()
                    }
                }
                onPressAndHold: {
                    hide()
                }

                Label {
                    visible: (cStep >= 0)
                    anchors.centerIn: parent
                    font.pixelSize: Theme.fontSizeTiny
                    text: cStep + 1
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
                    //console.log(freeDrawPolyCoordinatesArray)
                    //console.log(lineColorArray)
                    //console.log(lineWidthArray)
                    py.imagePaintFunction( filePath, imageRatioSourceScreen, freeDrawPolyCoordinatesArray, lineColorArray, lineWidthArray )
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


    function notify( currentImagePath ) {
        popupPaint.opacity = 1.0
        pinchEnabled = false
        mainBackgroundRect.color = "transparent"
        filePath = currentImagePath
        freeDrawCanvas.clear_canvas()
        freeDrawPolyCoordinatesArray = []
        imageData = []
        cStep = -1
        lineColorArray = []
        lineWidthArray = []
        canvasFreeDrawing.width = imagePaintedWidth
        canvasFreeDrawing.height = imagePaintedHeight
    }

    function hide() {
        freeDrawCanvas.clear_canvas()
        freeDrawPolyCoordinatesArray = []
        imageData = []
        cStep = -1
        lineColorArray = []
        lineWidthArray = []
        popupPaint.opacity = 0.0
        pinchEnabled = true
        allowedOrientations = Orientation.All
    }


}
