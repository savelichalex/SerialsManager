//
//  Serials.swift
//  SerialsManager
//
//  Created by Admin on 05.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation

struct Serial {
    let path: NSURL
    let title: String
    var seasons: [Season]?
    let seasonsJSON: NSURL
    var active: Bool
}

struct Season {
    let path: NSURL
    let title: String
    let serial: Serial?
    var chapters: [Chapter]?
    let chaptersJSON: NSURL
    var active: Bool
}

struct Chapter {
    let path: NSURL
    let title: String
    let season: Season?
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
            var serial =
                Serial(
                    path: $0,
                    title: $0.lastPathComponent!,
                    seasons: nil,
                    seasonsJSON: NSURL.fileURLWithPath(($0.path! + "/seasons.json")),
                    active: false
                )
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
            var season =
                Season(
                    path: $0,
                    title: $0.lastPathComponent!,
                    serial: serial,
                    chapters: nil,
                    chaptersJSON: NSURL.fileURLWithPath(($0.path! + "/chapters.json")),
                    active: false
                )
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
            Chapter(path: $0, title: $0.lastPathComponent!, season: season)
        }
    } else {
        return nil
    }
}