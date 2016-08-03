//
//  Serials.swift
//  SerialsManager
//
//  Created by Admin on 05.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation

struct SerialData {
    let path: NSURL
    let title: String
    let seasonsJSON: NSURL
}

struct SeasonData {
    let path: NSURL
    let title: String
    let chaptersJSON: NSURL
}

struct ChapterData {
    let path: NSURL
    let title: String
    let raw: String
}

class Serial {
    var data: SerialData
    var seasons: [Season]?
    var active: Bool
    
    init(data: SerialData) {
        self.data = data
        seasons = nil
        active = false
    }
}

class Season {
    let data: SeasonData
    let serial: Serial?
    var chapters: [Chapter]?
    var active: Bool
    
    init(data: SeasonData, serial: Serial) {
        self.data = data
        self.serial = serial
        chapters = nil
        active = false
    }
}

class Chapter {
    let data: ChapterData
    let season: Season?
    
    init(data: ChapterData, season: Season) {
        self.data = data
        self.season = season
    }
}

func getDirs(path: NSURL) -> [NSURL]? {
    let dirs: [NSURL]?
    do {
        let directoryC = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(path, includingPropertiesForKeys: nil, options: [])
        dirs = directoryC.filter{ $0.hasDirectoryPath }.filter{ $0.lastPathComponent != ".git" && $0.lastPathComponent != ".idea" }
    } catch _ {
        dirs = nil
    }
    return dirs
}

func getFilesWithExtensions(dir: NSURL, fileExtension: String) -> [NSURL]? {
    let files: [NSURL]?
    do {
        let directoryC = try NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir, includingPropertiesForKeys: nil, options: [])
        files = directoryC.filter{ $0.pathExtension == fileExtension }
    } catch _ {
        files = nil
    }
    return files
}

func getSerials(serialsPath: NSURL) -> [Serial]? {
    let dirs = getDirs(serialsPath)
    if dirs != nil {
        return dirs!.map{
            let serial =
                Serial(
                    data: SerialData(
                        path: $0,
                        title: $0.lastPathComponent!,
                        seasonsJSON: NSURL.fileURLWithPath(($0.path! + "/seasons.json"))))
            serial.seasons = getSeasons($0, serial: serial)
            return serial
        }
    } else {
        return nil
    }
}

func getSeasons(seasonsPath: NSURL, serial: Serial) -> [Season]? {
    let dirs = getDirs(seasonsPath)
    if dirs != nil {
        return dirs!.map {
            let season =
                Season(
                    data: SeasonData(
                        path: $0,
                        title: $0.lastPathComponent!,
                        chaptersJSON: NSURL.fileURLWithPath(($0.path! + "/chapters.json"))
                    ),
                    serial: serial)
            season.chapters = getChapters($0, season: season)
            return season
        }
    } else {
        return nil
    }
}

func getChapters(chaptersPath: NSURL, season: Season) -> [Chapter]? {
    let files = getFilesWithExtensions(chaptersPath, fileExtension: "srt")
    if files != nil {
        return files!.map {
            do {
                let chapterText = try String(contentsOfURL: $0, encoding: NSUTF8StringEncoding)
                return Chapter(
                    data: ChapterData(path: $0, title: $0.lastPathComponent!, raw: chapterText),
                    season: season)
            } catch {
                exit(1)
            }
        }
    } else {
        return nil
    }
}