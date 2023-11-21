import QtQuick 2.6
import Sailfish.Silica 1.0


Rectangle {
    // inherited values
    property var flickable: parent
    property bool labelVisible : true
    property string labelModelTag : ""
    property real topPadding : 0
    property real bottomPadding : 0
    property color handleColor : Theme.highlightBackgroundColor

    // own values but overwritable
    property int scrollToNumber : 0
    property string showLabel : ""
    property int listcountMax : (flickable.count === undefined) ? 0 : flickable.count
    property real roundCornersRadius : Theme.paddingLarge

    id: scrollbar
    anchors.top: parent.top
    anchors.topMargin: topPadding
    anchors.bottom: parent.bottom
    anchors.bottomMargin: bottomPadding
    anchors.right: parent.right
    width: roundCornersRadius * 2
    radius: width / 2
    color: Theme.rgba(Theme.primaryColor, 0.075)
    visible: flickable.visibleArea.heightRatio < 1.0

    Rectangle {
        id: handle
        width: parent.width
        height: Math.max(roundCornersRadius*2, flickable.visibleArea.heightRatio * scrollbar.height)
        color: handleColor
        opacity: (clicker.drag.active ) ? 1 : 0.4
        radius: width / 2
    }
    Rectangle {
        id: scrollLabelBackground
        visible: labelVisible
        anchors.verticalCenter: handle.verticalCenter
        anchors.right: handle.left
        anchors.rightMargin: Theme.paddingLarge * 1.5
        width: scrollLabel.width + height*1.2
        height: roundCornersRadius * 2
        radius: roundCornersRadius
        color: handleColor
        opacity: (clicker.drag.active ) ? 1 : 0

        Label {
            id: scrollLabel
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            text: showLabel
        }
        Rectangle {
            anchors.left: parent.right
            anchors.leftMargin: -roundCornersRadius
            anchors.verticalCenter: parent.verticalCenter
            width: parent.anchors.rightMargin + 2*roundCornersRadius
            height: Theme.paddingSmall/3*2
            color: parent.color
        }
    }
    Binding {
        // jump handle to where the currently visible part of flickable ist
        target: handle
        property: "y"
        value: (flickable.visibleArea.yPosition) * (scrollbar.height - ( handle.height - (flickable.visibleArea.heightRatio * scrollbar.height)))
        when: !clicker.pressed
    }
    MouseArea {
        id: clicker
        anchors.fill: parent
        anchors.rightMargin: -Theme.paddingSmall
        anchors.leftMargin: -Theme.paddingSmall
        preventStealing: true
        drag {
            target: handle
            minimumY: 0
            maximumY: scrollbar.height - handle.height
            axis: Drag.YAxis
        }
        onMouseYChanged: {
            //flickable.contentY = handle.y / drag.maximumY * (flickable.contentHeight - flickable.height)
            scrollToNumber = Math.ceil(handle.y / drag.maximumY * listcountMax)
            if (scrollToNumber < 0) {
                scrollToNumber = 0
            } else if (scrollToNumber >= listcountMax) {
                scrollToNumber = listcountMax -1 // because index starts at 0, while count() starts at 1
            }
            showLabel = (flickable.model.get(scrollToNumber)[labelModelTag] !== undefined) ? flickable.model.get(scrollToNumber)[labelModelTag] : "" //flickable.model.get(scrollToNumber)[labelModelTag]
            flickable.positionViewAtIndex( scrollToNumber, ListView.Center)
            //flickable.contentY = handle.y / drag.maximumY * (flickable.contentHeight - flickable.height)
        }
        onClicked: {
            //flickable.contentY = mouse.y / scrollbar.height * (flickable.contentHeight - flickable.height)
            scrollToNumber = Math.ceil(mouse.y / scrollbar.height * listcountMax)
            showLabel = (flickable.model.get(scrollToNumber)[labelModelTag] !== undefined) ? flickable.model.get(scrollToNumber)[labelModelTag] : "" //flickable.model.get(scrollToNumber)[labelModelTag]
            flickable.positionViewAtIndex( scrollToNumber, ListView.Center )
        }
        //onReleased: console.log("released")
    }
}
