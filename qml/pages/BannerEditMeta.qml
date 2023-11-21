import QtQuick 2.6
import Sailfish.Silica 1.0


MouseArea {
    id: popupEditMeta
    z: 10
    width: parent.width
    height: parent.height
    visible: opacity > 0
    opacity: 0.0
    onClicked: {
        hide()
    }

    // UI variables
    property string oldIfdZone : ""
    property int oldTagNr : 0
    property string oldTagName : ""
    property string oldTagValue : ""
    property int oldListID
    property var filePath

    Behavior on opacity {
        FadeAnimator {}
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
            width: parent.width - 2*Theme.paddingMedium
            height: Theme.itemSizeHuge
            radius: Theme.paddingLarge
            border.width: 2
            border.color: Theme.highlightColor

            TextField {
                id: idTextFieldEditMeta
                anchors.centerIn: parent
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: Theme.highlightColor
                text: oldTagValue
                label: oldTagName
                inputMethodHints: Qt.ImhNoPredictiveText
                //validator: RegExpValidator { regExp: /[a-zA-Z0-9äöüÄÖÜ_=()\/.!?#+-]*$/ }
                EnterKey.onClicked: {
                    //if (text.length > 0) {
                        editMetaJPG( oldListID, text )
                        focus = false
                        hide()
                    //}
                }
            }
        }

    }


    function notify( color, filePathTag, ifd_zone, tag_nr, tagName, tagValue, listID ) {
        if (color && (typeof(color) != "undefined")) { idBackgroundRect.color = color }
        else { idBackgroundRect.color = Theme.rgba(Theme.highlightDimmerColor, 1) }
        oldIfdZone = ifd_zone
        oldTagNr = tag_nr
        oldTagName = tagName
        oldTagValue = tagValue
        oldListID = listID
        filePath = filePathTag

        idTextFieldEditMeta.focus = true
        popupEditMeta.opacity = 1.0
    }

    function hide() {
        idTextFieldEditMeta.focus = false
        popupEditMeta.opacity = 0.0
    }

    function editMetaJPG( oldListID, text ) {
        if (oldTagValue !== text) {
            py.editEXIFdata( filePath, oldIfdZone, oldTagNr, oldTagName, text )
            idListModelMetaInfo.setProperty(oldListID, "tagValue", text)
        }
    }

}
