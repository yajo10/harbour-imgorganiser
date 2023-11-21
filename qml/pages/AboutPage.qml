import QtQuick 2.6
import Sailfish.Silica 1.0
import "../modules/Opal/About"


AboutPageBase{
    id: root
    allowedOrientations: S.Orientation.All
    appName: "ImgOrganizer"
    appIcon: Qt.resolvedUrl("../cover/harbour-timeline.svg")
    appVersion: "0.6"
    description: "ImgOrganizer is an image gallery and viewer for SailfishOS with support for chronological timeline, custom albums, folders as well as search for date and filename."
    authors: "2023 yajo, 2023 Tobias Planitzer"
    licenses: License { spdxId: "GPL-3.0" }
    attributions: OpalAboutAttribution {}
    sourcesUrl: "https://github.com/yajo10/harbour-imgorganizer/"
    extraSections: [
        InfoSection {
            title: qsTr("Usability hints:")
            text: qsTr("Be aware that adding a large number of images to your device at once may slow down the following app-start until new thumbnails are generated. ")
                  + qsTr("For syncronizing images and database in case another app alters a file while ImgOrganizer is running, press-and-hold Settings symbol or restart this app. ")
        },
        InfoSection {
            title: qsTr("Metadata")
            text: qsTr("Activating 'Metadata' for dateTime and album keywords applies EXIF/IPTC data from JPG files directly. ")
                  + qsTr("When assigning an album this info will also be stored as keyword inside your JPG file for use with external programs. ")
                  + qsTr('To set multiple keywords, you may use commas (",") as separator in album-name. ')
        }
    ]
}
