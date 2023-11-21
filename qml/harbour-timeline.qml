import QtQuick 2.6
import Sailfish.Silica 1.0
import QtQuick.LocalStorage 2.0 // DB reading and writing
import "pages"

ApplicationWindow {
    id: idApplicationWindow
    property bool reloadDBSettings : false
    property bool settingsRequireRescanImages : false
    property bool clearDBoldEntries : false
    property bool reloadImage : false // for watchdog when editing images
    property int appHeight : height
    property int appWidth : width
    property bool finishedLoading : false

    // load settings from DB
    property var currentView : storageItem.getSetting("infoCurrentView", "timeline")
    property var amountDetails : parseInt(storageItem.getSetting("infoTimeShowDetailsIndex", 0))
    property var infoWidthDevider : parseInt(storageItem.getSetting("infoWidthDevider", 3))
    property var infoActivateCoverImages : parseInt(storageItem.getSetting("infoActivateCoverImages", 0))
    property var coverImageChangeInterval : parseInt(storageItem.getSetting("coverImageChangeInterval", 5000))

    // cover progress and image path
    property bool coverpageActiveFocus : false
    property bool viewpageActiveFocus : false
    property int currentlyScannedImage
    property int maxScannedImages

    //slideshow timer in ViewPage, activates also on CoverPage
    property bool runSlideshowTimer : false
    property string currentSlideshowImagePath : ""

    // random images buffer
    property string coverImagePath : ""
    property var previousRandomImagesAlbumArray : []


    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations
    onVisibleChanged: {
        // reload all lists when returned to this app from another app
        // advantage = timeline updates automatically when other apps delete image while harbour-timeline is open
        // disadvantage: when in album view, images will not be shown -> not useful here yet
        if (visible === true) {
            //reloadDBSettings = true
            //reloadDBSettings = false
        }
    }


    Item {
        id: storageItem
        function getDatabase() {
           return storageItem.LocalStorage.openDatabaseSync("Timeline", "0.1", "TimelineDatabase", 5000000);
        }
        function removeFullTable (tableName) {
            var db = getDatabase();
            var res = "";
            db.transaction(function(tx) { tx.executeSql('DROP TABLE IF EXISTS ' + tableName) });
        }
        function setSetting(setting, value) {
          var db = getDatabase();
          var res = "";
           db.transaction(function(tx) {
             tx.executeSql('CREATE TABLE IF NOT EXISTS settings(setting TEXT UNIQUE, value TEXT)');
            var rs = tx.executeSql('INSERT OR REPLACE INTO settings VALUES (?,?);', [setting,value]);
              if (rs.rowsAffected > 0) {
               res = "OK";
              } else {
               res = "Error";
              }
            }
           );
           return res;
        }
        function getSetting(setting, default_value) {
           var db = getDatabase();
           var res="";
           try {
            db.transaction(function(tx) {
             var rs = tx.executeSql('SELECT value FROM settings WHERE setting=?;', [setting]);
              if (rs.rows.length > 0) {
               res = rs.rows.item(0).value;
               if (res === null) {
                //make sure it is not null but an empty string
                res = ""
               }
              } else {
               res = default_value;
              }
            })
           } catch (err) {
             //console.log("Database " + err);
            res = default_value;
           };
           return res
        }

        function addKeywords(albumPath, value) {
          var db = getDatabase();
          var res = "";
           db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS keywords(path TEXT UNIQUE, value TEXT)');
            var rs = tx.executeSql('INSERT OR REPLACE INTO keywords VALUES (?,?);', [albumPath,value]);
              if (rs.rowsAffected > 0) {
               res = "OK";
              } else {
               res = "Error";
              }
            }
           );
           return res;
        }
        function getKeywords(albumPath, default_value) {
           var db = getDatabase();
           var res="";
           try {
            db.transaction(function(tx) {
             var rs = tx.executeSql('SELECT value FROM keywords WHERE path=?;', [albumPath]);
              if (rs.rows.length > 0) {
               res = rs.rows.item(0).value;

              } else {
               res = default_value;
              }
            })
           } catch (err) {
             //console.log("Database " + err);
            res = default_value;
           };
           return res
        }
        function removeKeywords( path2remove ) {
          var db = getDatabase();
          var res = "";
           db.transaction(function(tx) {
             tx.executeSql('CREATE TABLE IF NOT EXISTS keywords(path TEXT UNIQUE, value TEXT)');
            var rs = tx.executeSql('DELETE FROM keywords WHERE path = ?;', [ path2remove ]);
              if (rs.rowsAffected > 0) {
               res = "OK";
              } else {
               res = "Error";
              }
            }
           );
           return res;
        }
        function getKeywordsCount (albumName, default_value) {
             var db = getDatabase();
             var res="";
             try {
              db.transaction(function(tx) {
               var rs = tx.executeSql('SELECT count(*) AS some_info FROM keywords WHERE value=?;', [albumName]);
                if (rs.rows.length > 0) {
                 res = rs.rows.item(0).some_info;
                } else {
                 res = default_value;
                }
              })
             } catch (err) {
              //console.log("Database " + err);
              res = default_value;
             };
             return res
        }
        function getAllStoredKeywords ( default_value ) {
            var db = getDatabase();
            var res=[];
            try {
             db.transaction(function(tx) {
               var rs = tx.executeSql('SELECT * FROM keywords');
               // populate array, list or model with content
               if (rs.rows.length > 0) {
                     for (var i = 0; i < rs.rows.length; i++) {
                          var myItem = rs.rows.item(i)
                          res.push(myItem.path)
                     }
                } else {
                 res = default_value;
                }
              })
             } catch (err) {
               //console.log("Database " + err);
              res = default_value;
             };
             return res
        }

        function addAlbum(albumPath, value) {
          var db = getDatabase();
          var res = "";
           db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS album(path TEXT UNIQUE, value TEXT)');
            var rs = tx.executeSql('INSERT OR REPLACE INTO album VALUES (?,?);', [albumPath,value]);
              if (rs.rowsAffected > 0) {
               res = "OK";
              } else {
               res = "Error";
              }
            }
           );
           return res;
        }
        function getAlbum(albumPath, default_value) {
           var db = getDatabase();
           var res="";
           try {
            db.transaction(function(tx) {
             var rs = tx.executeSql('SELECT value FROM album WHERE path=?;', [albumPath]);
              if (rs.rows.length > 0) {
               res = rs.rows.item(0).value;

              } else {
               res = default_value;
              }
            })
           } catch (err) {
             //console.log("Database " + err);
            res = default_value;
           };
           return res
        }
        function removeAlbum( path2remove ) {
          var db = getDatabase();
          var res = "";
           db.transaction(function(tx) {
             tx.executeSql('CREATE TABLE IF NOT EXISTS album(path TEXT UNIQUE, value TEXT)');
            var rs = tx.executeSql('DELETE FROM album WHERE path = ?;', [ path2remove ]);
              if (rs.rowsAffected > 0) {
               res = "OK";
              } else {
               res = "Error";
              }
            }
           );
           return res;
        }
        function getAlbumCount (albumName, default_value) {
             var db = getDatabase();
             var res="";
             try {
              db.transaction(function(tx) {
               var rs = tx.executeSql('SELECT count(*) AS some_info FROM album WHERE value=?;', [albumName]);
                if (rs.rows.length > 0) {
                 res = rs.rows.item(0).some_info;
                } else {
                 res = default_value;
                }
              })
             } catch (err) {
              //console.log("Database " + err);
              res = default_value;
             };
             return res
        }
        function getAllStoredImages ( default_value ) {
            var db = getDatabase();
            var res=[];
            try {
             db.transaction(function(tx) {
               var rs = tx.executeSql('SELECT * FROM album');
               // populate array, list or model with content
               if (rs.rows.length > 0) {
                     for (var i = 0; i < rs.rows.length; i++) {
                          var myItem = rs.rows.item(i)
                          res.push(myItem.path)
                     }
                } else {
                 res = default_value;
                }
              })
             } catch (err) {
               //console.log("Database " + err);
              res = default_value;
             };
             return res
        }
        function getAllStoredImagesAlbums ( default_path, default_value ) {
            var db = getDatabase();
            var res=[];
            try {
             db.transaction(function(tx) {
               var rs = tx.executeSql('SELECT * FROM album');
               // populate array, list or model with content
               if (rs.rows.length > 0) {
                     for (var i = 0; i < rs.rows.length; i++) {
                          var myItem = rs.rows.item(i)
                          res.push([myItem.path, myItem.value])
                     }
                } else {
                 res = [default_path, default_value];
                }
              })
             } catch (err) {
               //console.log("Database " + err);
              res = [default_path, default_value];
             };
             return res
        }
    }
}
