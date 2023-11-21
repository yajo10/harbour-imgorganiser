import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupColorize
    z: 10
    width: parent.width
    height: parent.height
    opacity: 0.0
    visible: opacity > 0
    onClicked: {
        hide()
    }

    Behavior on opacity {
        //FadeAnimator {}
    }
    Rectangle {
        id: idBackgroundRect
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: upperFreeHeight
        width: Theme.itemSizeLarge * 4
        height: idImageColorSliderColumn.height
        radius: Theme.paddingLarge
        color: buttonBackgroundColor
        border.width: 2
        border.color: Theme.highlightColor

        Column {
            id: idImageColorSliderColumn
            width: parent.width
            spacing: Theme.paddingSmall

            Slider {
                id: idBrightnessSlider
                width: parent.width
                height: Theme.itemSizeLarge
                minimumValue: -1
                maximumValue: 1
                value: 0
                stepSize: 0.01
                smooth: true
                leftMargin: Theme.paddingLarge * 2
                rightMargin: Theme.paddingLarge * 2
                label: "brightness"
                onValueChanged: idImagePreviewColors.brightness = value
            }
            Slider {
                id: idContrastSlider
                width: parent.width
                height: Theme.itemSizeLarge
                minimumValue: -1
                maximumValue: 1
                value: 0
                stepSize: 0.01
                smooth: true
                leftMargin: Theme.paddingLarge * 2
                rightMargin: Theme.paddingLarge * 2
                label: "contrast"
                onValueChanged: idImagePreviewColors.contrast = value
            }
        }
        IconButton {
            anchors.verticalCenter: idImageColorSliderColumn.verticalCenter
            anchors.horizontalCenter: idImageColorSliderColumn.left
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
            anchors.verticalCenter: idImageColorSliderColumn.verticalCenter
            anchors.horizontalCenter: idImageColorSliderColumn.right
            height: Theme.itemSizeLarge * 1.1
            width: height
            icon.scale: 1
            icon.source: "image://theme/icon-m-accept?"
            onClicked: {
                finishedLoadingView = false
                var brightnessFactor = idBrightnessSlider.value
                var contrastFactor = idContrastSlider.value
                py.imageColorizeFunction( currentImagePath, brightnessFactor, contrastFactor )
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



    function notify() {
        popupColorize.opacity = 1.0
        pinchEnabled = false
    }

    function hide() {
        popupColorize.opacity = 0.0
        pinchEnabled = true
        allowedOrientations = Orientation.All
        idBrightnessSlider.value = 0
        idContrastSlider.value = 0
        idImagePreviewColors.brightness = 0
        idImagePreviewColors.contrast = 0
    }
}
