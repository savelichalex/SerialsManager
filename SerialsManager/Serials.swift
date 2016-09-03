//
//  Serials.swift
//  SerialsManager
//
//  Created by Admin on 05.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation

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
        seasons = nil
    }
}

class Season {
    let data: SeasonData
    let serial: Serial?
    var chapters: [Chapter]?
    
    init(data: SeasonData, serial: Serial) {
        self.data = data
        self.serial = serial
        chapters = nil
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
                        title: $0.lastPathComponent!))
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
                        title: $0.lastPathComponent!
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
        return files!.enumerate().map { (index, element) in
            do {
                let chapterText = try String(contentsOfURL: element, encoding: NSUTF8StringEncoding)
                return Chapter(
                    data: ChapterData(
                        title: String(index + 1),
                        raw: chapterText),
                    season: season)
            } catch {
                exit(1)
            }
        }
    } else {
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

func updateChapterData(chapter: Chapter, text: String?) -> Void {
    let newData = ChapterData(
        title: chapter.data.title,
        raw: text
    )
    chapter.data = newData
}

class ListNode<T> {
    var value: T
    var next: ListNode? = nil
    
    init(_ value: T) {
        self.value = value
    }
    
    static func arrayToList(arr: [T]) -> ListNode<T> {
        var root: ListNode<T>? = nil
        var prev: ListNode<T>? = nil
        for el in arr {
            guard root != nil else {
                root = ListNode(el)
                prev = root!
                continue
            }
            let newNode = ListNode(el)
            prev!.next = newNode
            prev = newNode
        }
        return root!
    }
}

class SerialsService {
    static func parseSerials(serials: ListNode<EntityJSON>?, _ seasons: ListNode<Entities>?, _ chapters: ListNode<[[ChapterData]]>?, _ result: NSMutableArray = NSMutableArray()) -> [Serial] {
        guard let serial = serials,
            let season = seasons,
            let chapter = chapters else {
                return result.flatMap {
                    $0 as? Serial
                }
        }
        let newSerial =
            Serial(
                data: SerialData(
                    title: serial.value.title
                ))
        newSerial.seasons = parseSeasons(
            season.value,
            chapter.value,
            newSerial)
        result.addObject(
            newSerial
        )
        return parseSerials(
            serial.next,
            season.next,
            chapter.next,
            result)
    }
    
    static func parseSerials(serials: Entities, _ seasons: [Entities], _ chapters: [[[ChapterData]]]) -> [Serial] {
        return parseSerials(
            ListNode.arrayToList(serials),
            ListNode.arrayToList(seasons),
            ListNode.arrayToList(chapters)
        )
    }
    
    static func parseSeasons(seasons: ListNode<EntityJSON>?, _ chapters: ListNode<[ChapterData]>?, _ serial: Serial, _ result: NSMutableArray = NSMutableArray()) -> [Season] {
        guard let season = seasons,
            let chapter = chapters else {
                return result.flatMap {
                    $0 as? Season
                }
        }
        let newSeason =
            Season(
                data: SeasonData(
                    title: season.value.title
                ),
                serial: serial
        )
        newSeason.chapters = parseChapters(
            chapter.value,
            newSeason
        )
        result.addObject(newSeason)
        return parseSeasons(
            season.next,
            chapter.next,
            serial,
            result
        )
    }
    
    static func parseSeasons(seasons: Entities, _ chapters: [[ChapterData]], _ serial: Serial) -> [Season] {
        return parseSeasons(
            ListNode.arrayToList(seasons),
            ListNode.arrayToList(chapters),
            serial)
    }
    
    static func parseChapters(chapters: ListNode<ChapterData>?, _ season: Season, _ result: NSMutableArray = NSMutableArray()) -> [Chapter] {
        guard let chapter = chapters else {
            return result.flatMap {
                $0 as? Chapter
            }
        }
        let newChapter =
            Chapter(data: chapter.value, season: season)
        result.addObject(newChapter)
        return parseChapters(
            chapter.next,
            season,
            result
        )
    }
    
    static func parseChapters(chapters: [ChapterData], _ season: Season) -> [Chapter] {
        return parseChapters(
            ListNode.arrayToList(chapters),
            season)
    }
}