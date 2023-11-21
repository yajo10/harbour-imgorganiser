import QtQuick 2.6
import Sailfish.Silica 1.0


Page {
    id: page
    allowedOrientations: Orientation.Portrait //All

    SilicaFlickable {
        id: listView
        anchors.fill: parent
        contentHeight: idColumn.height  // Tell SilicaFlickable the height of its content.

        VerticalScrollDecorator {}

        Column {
            id: idColumn
            x: Theme.paddingLarge
            width: parent.width - 2*x

            Label {
                width: parent.width
                height: Theme.itemSizeLarge
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: Theme.fontSizeLarge
                color: Theme.primaryColor
                text: qsTr("ImgOrganizer")
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Image {
                width: parent.width
                height: Theme.itemSizeHuge
                source: "../cover/harbour-timeline.svg"
                sourceSize.width: height //Theme.itemSizeLarge
                sourceSize.height: height //Theme.itemSizeLarge
                fillMode: Image.PreserveAspectFit
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge * 2.5
            }

            Label {
                x: Theme.paddingMedium
                width: parent.width - 2*x
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                text: qsTr("ImgOrganizer is an image gallery and viewer for SailfishOS with support for chronological timeline, custom albums, folders as well as search for date and filename. ")
                    + qsTr("Thanksgiving, feedback and support is always welcome. ")
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge * 2.5
            }

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.secondaryColor
                wrapMode: Text.Wrap
                text: qsTr("Copyright © 2021-2023 Tobias Planitzer")
                + "\n" + qsTr("tp.labs@protonmail.com")
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge * 2.5
            }

            Label {
                x: Theme.paddingMedium
                width: parent.width - 2*x
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                font.bold: true
                text: qsTr("Usability hints: ")
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Label {
                x: Theme.paddingMedium
                width: parent.width - 2*x
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                text: qsTr("Be aware that adding a large number of images to your device at once may slow down the following app-start until new thumbnails are generated. ")
                    + qsTr("For syncronizing images and database in case another app alters a file while ImgOrganizer is running, press-and-hold Settings symbol or restart this app. ")
            }
            Item {
                width: parent.width
                height: Theme.paddingLarge
            }

            Label {
                x: Theme.paddingMedium
                width: parent.width - 2*x
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
                text: qsTr("Activating 'Metadata' for dateTime and album keywords applies EXIF/IPTC data from JPG files directly. ")
                    + qsTr("When assigning an album this info will also be stored as keyword inside your JPG file for use with external programs. ")
                    + qsTr('To set multiple keywords, you may use commas (",") as separator in album-name. ')
            }



            Item {
                width: parent.width
                height: Theme.paddingLarge
            }
        }

    } // end Silica Flickable
}
