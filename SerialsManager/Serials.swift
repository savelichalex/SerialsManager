//
//  Serials.swift
//  SerialsManager
//
//  Created by Admin on 05.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation
import SwiftyDropbox

private let badFiles    = [".git", ".idea"]
private let chaptersExt = "srt"

struct SerialData {
    let title: String
}

struct SeasonData {
    let title: String
}

struct ChapterData {
    let title: String?
    let raw: String?
}

class Serial {
    var data: SerialData
    var seasons: [Season]?
    
    init(data: SerialData) {
        self.data = data
        seasons = []
    }
}

class Season {
    let data: SeasonData
    let serial: Serial?
    var chapters: [Chapter]?
    
    init(data: SeasonData, serial: Serial) {
        self.data = data
        self.serial = serial
        chapters = []
    }
}

class Chapter {
    var data: ChapterData
    let season: Season?
    
    init(data: ChapterData, season: Season) {
        self.data = data
        self.season = season
    }
}

func getDirs(path: NSURL) -> [NSURL]? {
    if let directoryC = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(path,
                                                                                     includingPropertiesForKeys: nil,
                                                                                     options: []) {
        return directoryC.filter { $0.hasDirectoryPath }.filter { !badFiles.contains($0.lastPathComponent ?? "") }
    }
    return nil
}

func getFilesWithExtensions(dir: NSURL, fileExtension: String) -> [NSURL]? {
    if let directoryC = try? NSFileManager.defaultManager().contentsOfDirectoryAtURL(dir,
                                                                                     includingPropertiesForKeys: nil,
                                                                                     options: []) {
        return directoryC.filter { $0.pathExtension == fileExtension }
    }
    return nil
}

func getSerials(serialsPath: NSURL) -> [Serial]? {
    guard let dirs = getDirs(serialsPath) else {
        return nil
    }

    return dirs.map {
        let serial = Serial(data: SerialData(title: $0.lastPathComponent!))
        serial.seasons = getSeasons($0, serial: serial)
        return serial
    }
}

func getSeasons(seasonsPath: NSURL, serial: Serial) -> [Season]? {
    guard let dirs = getDirs(seasonsPath) else {
        return nil
    }

    return dirs.map {
        let season = Season(data: SeasonData(title: $0.lastPathComponent!), serial: serial)
        season.chapters = getChapters($0, season: season)
        return season
    }
}

func getChapters(chaptersPath: NSURL, season: Season) -> [Chapter]? {
    guard let files = getFilesWithExtensions(chaptersPath, fileExtension: chaptersExt) else {
        return nil
    }

    return files.enumerate().flatMap { (index, element) in
        if let chapterText = try? String(contentsOfURL: element, encoding: NSUTF8StringEncoding) {
            return Chapter(data: ChapterData(title: String(index + 1), raw: chapterText), season: season)
        }
        return nil
    }
}

func addNewChapter(season: Season) -> Chapter {
    let newChapter =
        Chapter(
            data: ChapterData(title: String((season.chapters?.count ?? 0) + 1), raw: nil),
            season: season
        )
    season.chapters?.append(newChapter)
    return newChapter
}

func addNewSeason(serial: Serial) -> Season {
    let newSeason =
        Season(
            data: SeasonData(title: String((serial.seasons?.count ?? 0) + 1)),
            serial: serial
    )
    serial.seasons?.append(newSeason)
    return newSeason
}

func addNewSerial(inout serials: [Serial]) -> Serial {
    let newSerial =
        Serial(
            data: SerialData(title: "new serial")
        )
    serials.append(newSerial)
    return newSerial
}

func updateChapterData(chapter: Chapter, text: String?) -> Void {
    let newData = ChapterData(
        title: chapter.data.title,
        raw: text
    )
    chapter.data = newData
}
