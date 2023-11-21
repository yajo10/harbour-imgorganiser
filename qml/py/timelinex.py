#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import pyotherside
import os
import datetime
import re
import glob
from pathlib import Path            # for finding $HOME directory path
from operator import itemgetter     # for sorting a list of tuples by given item-index
import iptcinfo3                    # standalone IPTC metadata
import piexif                       # standalone EXIF metadata
import piexif.helper
import subprocess                   # for running shell commands as separate processes
import zipfile                      # for sharing multiple files at once, e.g. on bluetooth
try:
    import PIL
    try:
        version = float((PIL.__version__).split(".")[0])
        if version < 7:
            pyotherside.send('pillowNotAvailable', "tooOld" )
    except:
        pyotherside.send('pillowNotAvailable', "tooOld" )
    from PIL import Image
    from PIL import ImageColor
    from PIL import ImageDraw
    from PIL import ImageOps
    from PIL import ImageEnhance
except ImportError:
    pyotherside.send('pillowNotAvailable', "notInstalled")
#from concurrent.futures import ThreadPoolExecutor   # activates multithreading





# variables, readable
extensions = ('.jpg', '.JPG', '.jpeg', '.JPEG', '.png', '.PNG', '.tif', '.TIF', '.tiff', '.TIFF','.bmp', '.BMP', '.gif', '.GIF')
exifEnabledExtensions = ('.jpg', '.JPG', '.jpeg', '.JPEG', '.tif', '.tiff', '.TIF', '.TIFF')
iptcEnabledExtensions = ('.jpg', '.JPG', '.jpeg', '.JPEG')





# image editing: general file checks if metadata can be saved
def bool_canSaveWithExif ( filePath ):
    if filePath.endswith( exifEnabledExtensions ):
        file_modificationDateMS = os.path.getmtime(filePath)
        timeUTC_object_created = datetime.datetime.utcfromtimestamp(file_modificationDateMS)
        creationDateMS_string = timeUTC_object_created.strftime('%Y:%m:%d %H:%M:%S')
        try:
            exif_dict = piexif.load(filePath)
            # remove the orientation EXIF tag, otherwise some images will be falsely rotated
            exif_dict["0th"][274] = ("").encode()
            # check for datetime in exif - if not, paste this datetime into EXIF, e.g. img without datetime gets rotated by pillow and saves as a new image but keeps correct timestamp
            try:
                if (piexif.ImageIFD.DateTime not in exif_dict["0th"]) and (piexif.ExifIFD.DateTimeOriginal not in exif_dict["Exif"]):
                    pyotherside.send('debugPythonLogs', "No EXIF datetime available, writing creationdate instead." )
                    exif_dict["0th"][piexif.ImageIFD.DateTime] = (creationDateMS_string).encode()
            except:
                pyotherside.send('debugPythonLogs', "Error inserting exif datetime, but life goes on." )
            # store as bytes
            exif_bytes = piexif.dump(exif_dict)
            if exif_bytes is None:
                saveWithExif = False
                exif_bytes = 0
            else:
                saveWithExif = True
        except:
            saveWithExif = False
            exif_bytes = 0
    else:
        saveWithExif = False
        exif_bytes = 0
    return saveWithExif, exif_bytes


def bool_canSaveWithIPTC( filePath ):
    iptc_keywords = []
    if filePath.endswith( iptcEnabledExtensions ):
        try:
            iptc_info = iptcinfo3.IPTCInfo(filePath)
            if iptc_info is None:
                saveWithIPTC = False
                iptc_info = 0
            else:
                saveWithIPTC = True
        except:
            saveWithIPTC = False
            iptc_info = 0
    else:
        saveWithIPTC = False
        iptc_info = 0
    return saveWithIPTC, iptc_info


def saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info ):
    if saveWithExif is True:
        output_img.save(filePath, compress_level=1, exif=exif_bytes)
    else:
        output_img.save(filePath, compress_level=1)
    if saveWithIPTC is True:
        iptc_info.save_as( filePath )
    pyotherside.send('updateImage', )



# image editing functions  with pillow
def imageRotateFunction ( filePath, targetAngle ):
    img = Image.open(filePath)
    saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
    saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
    img = ImageOps.exif_transpose(img)
    output_img = img.rotate(int(targetAngle), expand = True) # 90=left / 270=right
    saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
    img.close()
    output_img.close()


def imageFlipMirrorFunction ( filePath, targetDirection ):
    img = Image.open(filePath)
    saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
    saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
    img = ImageOps.exif_transpose(img)
    if "vertical" in targetDirection:
        output_img = ImageOps.flip(img)
    else: # "horizontal"
        output_img = ImageOps.mirror(img)
    saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
    img.close()
    output_img.close()


def imageCropFunction ( filePath, rectX, rectY, rectWidth, rectHeight, scaleFactor ):
    img = Image.open(filePath)
    saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
    saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
    img = ImageOps.exif_transpose(img)
    rectX_real = int(rectX * scaleFactor)
    rectY_real = int(rectY * scaleFactor)
    rectWidth_real = int(rectWidth * scaleFactor)
    rectHeight_real = int(rectHeight * scaleFactor)
    area = (rectX_real, rectY_real, rectX_real+rectWidth_real, rectY_real+rectHeight_real)
    output_img = img.crop(area)
    saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
    img.close()
    output_img.close()
    newFileSize = os.stat(filePath).st_size
    pyotherside.send('updateSingleFileSize', filePath, newFileSize )


def imageColorizeFunction ( filePath, brightnessFactor, contrastFactor ):
    brightnessFactor = float(brightnessFactor) + 1
    contrastFactor = float(contrastFactor) + 1
    img = Image.open(filePath)
    saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
    saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
    img = ImageOps.exif_transpose(img)
    if img.mode not in ('RGBA'):
        img = img.convert('RGBA')
    if brightnessFactor != 1:
        output_img_brightness = ImageEnhance.Brightness(img)
        output_img_brightness = output_img_brightness.enhance(brightnessFactor)
    else:
        output_img_brightness = img
    if contrastFactor != 1:
        output_img = ImageEnhance.Contrast(output_img_brightness)
        output_img = output_img.enhance(contrastFactor)
    else:
        output_img = output_img_brightness
    saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
    img.close()
    output_img.close()


def imageResizeFunction ( filePath, targetWidth, targetHeight ):
    img = Image.open(filePath)
    saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
    saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
    img = ImageOps.exif_transpose(img)
    output_img = img.resize( (int(targetWidth), int(targetHeight)), Image.ANTIALIAS )
    saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
    img.close()
    output_img.close()
    pyotherside.send('batchResizeProgress', 100)
    newFileSize = os.stat(filePath).st_size
    pyotherside.send('updateSingleFileSize', filePath, newFileSize )

def imageBulkResizeFunction ( imagePathsList, targetWidth, targetHeight, targetDirection ):
    allfilePathList = []
    allfilePathList = imagePathsList.split("|||")
    amountFiles = len(allfilePathList)
    progressCounter = 0
    for filePath in allfilePathList:
        if len(filePath) > 0: # make sure that file actually exists
            img = Image.open(filePath)
            saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
            saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
            img = ImageOps.exif_transpose(img)
            if "preferWidth" in targetDirection:
                baseWidth = int(targetWidth)
                widthPercent = (baseWidth/float(img.size[0]))
                propHeight = int((float(img.size[1])*float(widthPercent)))
                output_img = img.resize( (baseWidth, propHeight), Image.ANTIALIAS )
            else:
                baseHeight = int(targetHeight)
                heightPercent = (baseHeight/float(img.size[1]))
                propWidth = int((float(img.size[0])*float(heightPercent)))
                output_img = img.resize( (propWidth, baseHeight), Image.ANTIALIAS )
            saveEditedImage ( output_img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
            img.close()
            output_img.close()

            newFileSize = os.stat(filePath).st_size
            pyotherside.send('updateSingleFileSize', filePath, newFileSize )
            progressCounter += 1
            progressResizing = progressCounter / amountFiles * 100
            pyotherside.send('batchResizeProgress', progressResizing)

def imagePaintFunction ( filePath, scaleFactor, freeDrawPolyCoordinatesArray, lineColorArray, lineWidthArray ):
    img = Image.open(filePath)
    saveWithExif, exif_bytes = bool_canSaveWithExif( filePath )
    saveWithIPTC, iptc_info = bool_canSaveWithIPTC( filePath )
    img = ImageOps.exif_transpose(img)
    draw = ImageDraw.Draw(img)
    for i in range (0, len(freeDrawPolyCoordinatesArray)) :
        coordinatesList = list( freeDrawPolyCoordinatesArray[i].split(";") )
        lineWidth = int( float(lineWidthArray[i]) * float(scaleFactor) )
        lineColor = ImageColor.getrgb(lineColorArray[i])
        del coordinatesList[-1] # remove last comma
        coordinatesList = list(map(float, coordinatesList))
        coordinatesList = [i * float(scaleFactor) for i in coordinatesList]
        pairSublist = []
        fullPairsList = []
        for i in range(0, len(coordinatesList)-1, 2):
            pairSublist.append ( coordinatesList[i] )
            pairSublist.append ( coordinatesList[i+1] )
            fullPairsList.append ( tuple(pairSublist) )
            pairSublist.clear()
        coordinatesTuples = tuple(fullPairsList)
        draw.line( (coordinatesTuples), fill = lineColor, width = lineWidth, joint = 'curve')
    saveEditedImage ( img, filePath, saveWithExif, exif_bytes, saveWithIPTC, iptc_info )
    img.close()



# general organizing functions
def scanForImages (folders2scanHOME, folders2scanEXTERN, sdCards2scanEXTERN, showDirection, creationModificationDate, showHiddenFiles, findExifAlbum):
    dirsToScan = []
    homeDir = str(Path.home())

    # remove possible tmp files
    tempPath = homeDir + "/Downloads/" + "ImgOrganizer.zip"
    if os.path.exists(tempPath):
        os.remove(tempPath)

    #if folders2scanHOME[0] is not "":
    if folders2scanHOME[0] != "":
        for folders in folders2scanHOME:
            folderPath = homeDir + folders
            if os.path.exists(folderPath):
                dirsToScan.append(folderPath)

    #convert numeric sdCards2scanEXTERN to a full path
    #if sdCards2scanEXTERN[0] is not "":
    if sdCards2scanEXTERN[0] != "":
        extCardPathsToScan = []
        if len(glob.glob("/run/media/*/*")) != 0:
            for cardNumber in sdCards2scanEXTERN:
                sdCardPath = str((glob.glob("/run/media/*/*"))[int(cardNumber)-1])
                extCardPathsToScan.append (sdCardPath)
        else:
            extCardPathsToScan.append ("/run/media")

        helperCounter = 0
        for folders in folders2scanEXTERN:
            folderPath = extCardPathsToScan[helperCounter] + folders
            #pyotherside.send('debugPythonLogs', folderPath)
            helperCounter = helperCounter + 1
            if os.path.exists(folderPath):
                dirsToScan.append(folderPath)

    # no dublicates in folders
    dirsToScan = [i for n, i in enumerate(dirsToScan) if i not in dirsToScan[:n]]

    # now get all files possible in all folders and subfolders
    global someCounter
    someCounter = 0
    filteredFilePathList = []
    for folder in dirsToScan:
        #pyotherside.send('debugPythonLogs', folder)
        for dirPath, dirNames, fileNames in os.walk(folder):
            if showHiddenFiles == 0: # exclude hidden files and folders
                fileNames = [f for f in fileNames if not f[0] == '.']
                dirNames[:] = [d for d in dirNames if not d[0] == '.']
            fileNames = [f for f in fileNames if f.endswith( extensions )]
            for f in fileNames:
                filePath = dirPath + os.sep + f
                if (".thumbnail" not in filePath and "?" not in filePath and "*" not in filePath):
                    filteredFilePathList.append( filePath )
                    #pyotherside.send('debugPythonLogs', filePath)
    #filteredFilePathList = [i for n, i in enumerate(filteredFilePathList) if i not in filteredFilePathList[:n]]        # no dublicates check, but unnecessary!!!
    imagesTotalAmount = len(filteredFilePathList)
    #pyotherside.send('debugPythonLogs', str(imagesTotalAmount) + " images found")

    # scan each file for meta info
    fileInfoList = []

    for filePath in filteredFilePathList:  # coment for multithreading
    # def scan4exifInfo(filePath):         # uncomment for multithreading
        #global someCounter                # uncomment for multithreading
        someCounter += 1
        pyotherside.send('scanProgress', someCounter, imagesTotalAmount)
        estimatedSize = os.stat(filePath).st_size

        # get timestamp from creation date
        if creationModificationDate == 0:
            timestampSource = "creationDate"
            timeMS_created = os.path.getctime(filePath) #file first created in MS since 1970

        # OR get timestamp from modification date
        elif creationModificationDate == 1:
            timestampSource = "modificationDate"
            timeMS_created = os.path.getmtime(filePath) #file last modified in MS since 1970

        # OR get timestamp from parsing fileName
        else: #creationModificationDate == 2:
            timestampSource = "parsedFilename"
            try:
                try:
                    match_str = (re.search(r'\d{4}\d{2}\d{2}', str(file))).group()
                    match_str = match_str[:4] + "-" + match_str[4:]
                    match_str = match_str[:7] + "-" + match_str[7:]
                except:
                    match_str = (re.search(r'\d{4}-\d{2}-\d{2}', str(file))).group()
                    #pyotherside.send('debugPythonLogs', "This filename is in a different format: " + file)

                #check if monthNr is actually not the dayNr, since some apps create YYYY/MM/DD and other YYYY/DD/MM
                if int(match_str[5:7]) > 12: # this will be a day then, since months only go up to 12
                    timeUTC_fromFilename = datetime.datetime.strptime(match_str, '%Y-%d-%m').date()
                else:
                    timeUTC_fromFilename = datetime.datetime.strptime(match_str, '%Y-%m-%d').date()

                # get a localized datetime object and convert to timestamp in MS
                dt = datetime.datetime(
                    year=timeUTC_fromFilename.year,
                    month=timeUTC_fromFilename.month,
                    day=timeUTC_fromFilename.day
                ).replace(tzinfo=datetime.timezone.utc).astimezone(tz=None)
                timeMS_created = dt.timestamp()

            except: # creation date = fallback if filename makes no sense
                timestampSource = "creationDate"
                timeMS_created = os.path.getctime(filePath) #file first created in MS since 1970
                #pyotherside.send('debugPythonLogs', "This filename can not be parsed for valid date: " + file)

        # try to find album and creation date time in metadata or filename - if enabled in settings ... ToDo: takes too long!!!
        foundAlbumTag = "|||"
        tempTimestampSource = timestampSource
        tempTimeMS_created = timeMS_created
        if findExifAlbum == 1: # if we scan for meta data in album
            # get EXIF date time
            if filePath.endswith( exifEnabledExtensions ):
                try:
                    exif_dict = piexif.load(filePath)
                    # check in first possible date block
                    if piexif.ImageIFD.DateTime in exif_dict["0th"]:
                        value = (exif_dict["0th"][piexif.ImageIFD.DateTime]).decode() # get rid of bytes format
                        timestampSource = "exifMetadata"
                        date_time_obj = datetime.datetime.strptime(str(value), '%Y:%m:%d %H:%M:%S')
                        timeMS_created = date_time_obj.timestamp()
                        #pyotherside.send('debugPythonLogs', "0th found some info: " + str(value) )
                    # check in second possible date block
                    elif piexif.ExifIFD.DateTimeOriginal in exif_dict["Exif"]:
                        value = (exif_dict["Exif"][piexif.ExifIFD.DateTimeOriginal]).decode() # get rid of bytes format
                        timestampSource = "exifMetadata"
                        date_time_obj = datetime.datetime.strptime(str(value), '%Y:%m:%d %H:%M:%S')
                        timeMS_created = date_time_obj.timestamp()
                        #pyotherside.send('debugPythonLogs', "EXIF found info: " + str(value) )
                    else:
                        timestampSource = tempTimestampSource
                        timeMS_created = tempTimeMS_created
                        #pyotherside.send('debugPythonLogs', "EXIF dict empty")
                except: # in case of error (e.g. non-ascii characters OR "0000:00:00 00:00:00" as value) -> use the date from previous info
                    timestampSource = tempTimestampSource
                    timeMS_created = tempTimeMS_created
                    #pyotherside.send('debugPythonLogs', "EXIF error parsing: " + filePath  )

            # get IPTC album keywords
            if filePath.endswith( iptcEnabledExtensions ):
                iptc_keywords = []
                foundAlbumTag = ""
                try:
                    iptc_info = iptcinfo3.IPTCInfo(filePath)
                    iptc_keywords = iptc_info['keywords']
                    if len(iptc_keywords) > 0:
                        for keyword in iptc_keywords:
                            if isinstance(keyword, bytes):
                                keyword = keyword.decode()
                            foundAlbumTag += str(keyword) + ", "
                        foundAlbumTag = foundAlbumTag[:-2]
                        #pyotherside.send('debugPythonLogs', foundAlbumTag )
                    else:
                        foundAlbumTag = "|||"
                except:
                    foundAlbumTag = "|||"

        # get creation date
        timeUTC_created = datetime.datetime.utcfromtimestamp(timeMS_created)
        # combine all infos and append to list
        fileInfoList.append((timeMS_created, filePath, timeUTC_created.year, timeUTC_created.month, timeUTC_created.day, estimatedSize, foundAlbumTag, timestampSource))

    # run above as function with multithreading .. why is it slower than single thread???
    # with ThreadPoolExecutor() as executor:
    #     executor.map(scan4exifInfo, filteredFilePathList)


    # sort according to date time direction
    if "0" in showDirection:
        fileInfoList.sort(key=itemgetter(0), reverse=True) # sort list of tuples by first item, requires import itemgetter
    else:
        fileInfoList.sort(key=itemgetter(0), reverse=False) # sort list of tuples by first item, requires import itemgetter

    # sendentire list over to QML
    pyotherside.send('returnSortedImageList2Model', fileInfoList)

    # save some memory
    someCounter = 0
    dirsToScan = []
    filteredFilePathList = []
    fileInfoList = []
    iptc_keywords = []
    extCardPathsToScan = []




def findClosestDate ( datesItems, targetDate ):
    if targetDate in datesItems:
        closestDate = targetDate
    else:
        closestDate = min(datesItems, key=lambda x: abs(x - targetDate))
    closestIndex = datesItems.index(closestDate)
    pyotherside.send('goToDateIndex', closestIndex)


def getEXIFdata ( filePath, creationDateMS, monthYear, day, folderPath, fileName, estimatedSize, album, imageWidth, imageHeight, timestampSource, isFavourite ):
    iptc_keywords = []
    exifInfoList = []
    availableExifInfosList = []

    # get IPTC infos
    if filePath.endswith( iptcEnabledExtensions ):
        try:
            iptc_info = iptcinfo3.IPTCInfo(filePath)
            iptc_keywords = iptc_info['keywords']
            category = "IPTC Keywords"
            value = ""
            if len(iptc_keywords) > 0:
                for keyword in iptc_keywords:
                    if isinstance(keyword, bytes):
                        keyword = keyword.decode()
                    value += str(keyword) + ", "
                value = value[:-2]
                tag = 0
                ifd = "none"
                exifInfoList.append((category, value, tag, ifd))
            else:
                pyotherside.send('debugPythonLogs', "IPTC data available, but no keywords.")
        except:
            pyotherside.send('debugPythonLogs', "Reading IPTC data failed.")

    # get EXIF infos
    if filePath.endswith( exifEnabledExtensions ):
        try:
            exif_dict = piexif.load(filePath)
            for ifd in ("0th", "Exif", "GPS", "1st"):
                for tag in exif_dict[ifd]:
                    category = piexif.TAGS[ifd][tag]["name"]
                    value = exif_dict[ifd][tag]
                    if isinstance(category, bytes):
                        category = category.decode()
                    if isinstance(value, bytes):
                        value = value.decode()
                    exifInfoList.append((category, value, tag, ifd))
                    output = str(category) + " | " + str(value)
                    #pyotherside.send('debugPythonLogs', output)
        except:
            pyotherside.send('debugPythonLogs', "Reading EXIF data failed.")
    pyotherside.send('returnEXIFinfoList', exifInfoList, availableExifInfosList, filePath, creationDateMS, monthYear, day, folderPath, fileName, estimatedSize, album, imageWidth, imageHeight, timestampSource, isFavourite )
    exifInfoList = []



def deleteFilesFunction ( deletePathArray, imagesWorkload2Rescan ):
    for deletePath in deletePathArray:
        os.remove ( deletePath )
    # trigger rescan from QML to re-fill all lists
    if (len(deletePathArray) >= imagesWorkload2Rescan):
        pyotherside.send('filesDeleted', )


def checkFileExistence( inWhichTable, filePath ):
    if not os.path.exists(filePath):
        pyotherside.send('removeEntryFromDB', inWhichTable, filePath)
    pyotherside.send('finishedRemovingEntriesFromDB', )



def renameOriginalFunction ( currentPath, newPath ) :
    os.rename("/" + currentPath, "/" + newPath)
    pyotherside.send('finishedRenaming', newPath)


def checkCMDexistance ( command ) :
    returnCode = subprocess.call(['which', str(command)], stdout=subprocess.DEVNULL)
    if returnCode == 0:
        pyotherside.send('returnCommandExists', str(command) )
    else:
        pyotherside.send('returnCommandExists', 'file browser not installed')


def runCMDtool ( command ) :
    returnCode = subprocess.run([ command ])


def getAmountExtPartitions() :
    amountExternalPartitions = len(glob.glob("/run/media/*/*"))
    pyotherside.send('returnAmountExtPartitions', amountExternalPartitions)


def insertMetadataKeywords ( tags, filePath, storeWhere ):
    try:
        if "in_IPTC" in storeWhere and filePath.endswith( iptcEnabledExtensions ):
            iptc_info = iptcinfo3.IPTCInfo(filePath, force=True)
            iptc_info['keywords'].clear()
            allKeywordsList = []
            allKeywordsList = tags.split(",")
            for keyWord in allKeywordsList:
                keyWord = keyWord.strip() #removes whitespaces from beginning and end
                if len(keyWord) > 0:
                    iptc_info['keywords'].append(bytes(keyWord, 'UTF-8'))
            iptc_info.save()  #iptc_info.save_as(filePath)
            #pyotherside.send('debugPythonLogs', "album in iptc saved")
        elif "in_EXIF" in storeWhere and filePath.endswith( iptcEnabledExtensions ):
            zeroth_ifd = {40094: tags.encode('utf16')} #=> piexif.ImageIFD.XPKeywords: "keywords_here".encode('utf16')
            exif_bytes = piexif.dump({"0th":zeroth_ifd})
            piexif.insert(exif_bytes, filePath)
            #pyotherside.send('debugPythonLogs', "album in exif saved")
    except:
        pyotherside.send('debugPythonLogs', "Adding Metadata not supported with this file.")

def editEXIFdata ( filePath, ifdZone, tagNr, tagName, tagValue ):
    if filePath.endswith( exifEnabledExtensions ):
        # insert EXIF infos
        #pyotherside.send('debugPythonLogs', ifdZone)
        #pyotherside.send('debugPythonLogs', tagNr)
        #pyotherside.send('debugPythonLogs', tagName)
        #pyotherside.send('debugPythonLogs', tagValue)
        try:
            exif_dict = piexif.load(filePath)
            exif_dict[ifdZone][tagNr] = tagValue.encode()
            '''
            for ifd in ("0th", "Exif", "GPS", "1st"):
                for tag in exif_dict[ifd]:
                    exif_dict[ifdZone][tagNr] = tagValue.encode()
                    #category = piexif.TAGS[ifd][tag]["name"]
                    # if isinstance(category, bytes):
                    #     category = category.decode()
                    # if str(category) in str(tagName):
                    #     exif_dict[ifd][tag] = tagValue.encode()
            '''
            exif_bytes = piexif.dump(exif_dict)
            piexif.insert(exif_bytes, filePath)
        except:
            pyotherside.send('debugPythonLogs', "Writing EXIF data failed, but life goes on.")
    pyotherside.send('finishedWritingMetadata', )



def removeMetadataKeywords ( filePath, storeWhere ):
    try:
        if "in_IPTC" in storeWhere and filePath.endswith( iptcEnabledExtensions ):
            iptc_info = iptcinfo3.IPTCInfo(filePath)
            iptc_info['keywords'].clear()
            iptc_info.save()
    except:
        pyotherside.send('debugPythonLogs', "Deleting Metadata not supported with this file.")


def packZipImagesTmp ( imagePathsList ) :
    targetPath = str(Path.home()) + "/Downloads/" + "ImgOrganizer.zip"
    allfilePathList = []
    allfilePathList = imagePathsList.split("|||")
    with zipfile.ZipFile(targetPath , "w") as zipF:
        for file in allfilePathList:
            if len(file) > 0:
                name_file_only= file.split(os.sep)[-1]
                zipF.write(file, name_file_only, compress_type=zipfile.ZIP_DEFLATED)
    pyotherside.send('zipFileCreated', targetPath)


# general color conversion functions
def argb2rgba ( paintColor ) :
    first2 = paintColor[1:3]
    last6 = paintColor[3:9]
    rgbaColor = "#" + last6 + first2
    return rgbaColor

def argb2rgb ( paintColor ) :
    first2 = paintColor[1:3]
    last6 = paintColor[3:9]
    rgbColor = "#" + last6
    return rgbColor

def rgb2argb ( paintColor ) :
    first2 = "ff"
    last6 = paintColor[1:7]
    argbColor = "#" + first2 + last6
    return argbColor

def argb2alpha ( paintColor ) :
    first2 = paintColor[1:3]
    alphaValue = int(first2, 16)
    return alphaValue


