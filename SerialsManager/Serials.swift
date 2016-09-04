//
//  Serials.swift
//  SerialsManager
//
//  Created by Admin on 05.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftyDropbox

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
        );
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
    
    let remoteDB: RemoteDB
    
    init(db: RemoteDB) {
        self.remoteDB = db
    }
    
    func getSerials() -> Promise<[Serial]> {
        return remoteDB.downloadJSON("/serials.json")
            .then { serials in
                let promises =
                    serials.map {
                        self.remoteDB.downloadJSON($0.path)
                }
                
                return join(promises)
                    .then { seasons -> (Entities, [Entities]) in
                        return (serials, seasons)
                }
            }.then { (data: (Entities, [Entities])) in
                let (serials, seasons) = data
                let promises =
                    seasons.reduce([], combine: +)
                        .map {
                            self.remoteDB.downloadJSON($0.path)
                }
                
                return join(promises)
                    .then { chapters -> (Entities, [Entities], [Entities]) in
                        return (serials, seasons, chapters)
                }
            }.then { (data: (Entities, [Entities], [Entities])) in
                let (serials, seasons, chapters) = data
                let promises =
                    chapters.reduce([], combine: +)
                        .map {
                            self.remoteDB.downloadData($0.path)
                }
                
                return join(promises)
                    .then { data -> (Entities, [Entities], [Entities], [NSData]) in
                        return (serials, seasons, chapters, data)
                }
            }.then { (data: (Entities, [Entities], [Entities], [NSData])) -> (Entities, [Entities], [[[ChapterData]]]) in
                let (serials, seasons, chapters, chaptersRawData) = data
                let (_, chaptersData) =
                    chapters.reduce((0, [])) { (acc: (Int, [[ChapterData]]), arr: [EntityJSON]) -> (Int,[[ChapterData]]) in
                        let (index1, result) = acc
                        return (
                            index1 + arr.count,
                            result + [
                                arr.enumerate().map { (index2: Int, data: EntityJSON) -> ChapterData in
                                    return ChapterData(
                                        title: data.title,
                                        raw: String(
                                            data: chaptersRawData[acc.0 + index2],
                                            encoding: NSUTF8StringEncoding
                                        )
                                    )
                                }
                            ]
                        )
                }
                var index = 0
                let newChaptersData =
                    seasons.map { (season: Entities) -> [[ChapterData]] in
                        let slice = chaptersData[index..<season.count]
                        index = index + season.count
                        var newArr = Array<[ChapterData]>()
                        for el in slice {
                            newArr.append(el)
                        }
                        return newArr
                }
                return (serials, seasons, newChaptersData)
            }.then { (data: (Entities, [Entities], [[[ChapterData]]])) -> [Serial] in
                let (serials, seasons, chapters) = data
                return self.parseSerials(serials, seasons, chapters)
        }
    }
    
    func saveSerials(serials: [Serial]) -> Promise<Void> {
        typealias Seasons = [Season];
        typealias Chapters = [Chapter];
        return uploadSerials(serials)
            .then { (serials: [Serial]) -> Promise<[Seasons]> in
                let promises =
                    serials.map { serial in
                        return self.uploadSeasons(
                            serial.seasons!,
                            prefix: "/" + serial.data.title
                        )
                }
                
                return join(promises)
            }
            .then { (seasons: [Seasons]) -> Seasons in
                return seasons.reduce([], combine: +)
            }.then { (seasons: Seasons) -> Promise<[Chapters]> in
                let promises =
                    seasons.map { season in
                        return self.uploadChapters(
                            season.chapters!,
                            prefix: "/" + season.serial!.data.title + "/" + season.data.title
                        )
                }
                
                return join(promises)
            }.then { _ -> Void in
                
        }
    }
    
    func parseSerials(serials: ListNode<EntityJSON>?, _ seasons: ListNode<Entities>?, _ chapters: ListNode<[[ChapterData]]>?, _ result: NSMutableArray = NSMutableArray()) -> [Serial] {
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
    
    func parseSerials(serials: Entities, _ seasons: [Entities], _ chapters: [[[ChapterData]]]) -> [Serial] {
        return parseSerials(
            ListNode.arrayToList(serials),
            ListNode.arrayToList(seasons),
            ListNode.arrayToList(chapters)
        )
    }
    
    func parseSeasons(seasons: ListNode<EntityJSON>?, _ chapters: ListNode<[ChapterData]>?, _ serial: Serial, _ result: NSMutableArray = NSMutableArray()) -> [Season] {
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
    
    func parseSeasons(seasons: Entities, _ chapters: [[ChapterData]], _ serial: Serial) -> [Season] {
        return parseSeasons(
            ListNode.arrayToList(seasons),
            ListNode.arrayToList(chapters),
            serial)
    }
    
    func parseChapters(chapters: ListNode<ChapterData>?, _ season: Season, _ result: NSMutableArray = NSMutableArray()) -> [Chapter] {
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
    
    func parseChapters(chapters: [ChapterData], _ season: Season) -> [Chapter] {
        return parseChapters(
            ListNode.arrayToList(chapters),
            season)
    }
    
    func uploadSerials(serials: [Serial]) -> Promise<[Serial]> {
        let serialsWithSeasons =
            serials.filter {
                $0.seasons != nil
        }
        guard serialsWithSeasons.count != 0  else {
            return Promise(serials)
        }
        return firstly { () -> Promise<[Files.FolderMetadata]> in
            // create folders first because I don't want to write JSON file
            // if an error happen
            let promises: [Promise<Files.FolderMetadata>] =
                serialsWithSeasons.map { (serial: Serial) -> Promise<Files.FolderMetadata> in
                    return self.remoteDB.createFolder("/" + serial.data.title)
            }
            return join(promises)
            }.then { (_: [Files.FolderMetadata]) throws -> Promise<String> in
                return Promise { resolve, reject in
                    do {
                        let serialsJSON = try SerialsService.toJSON(serials) { serial in
                            let serialDict = NSMutableDictionary()
                            serialDict.setValue(serial.data.title, forKey: "title")
                            serialDict.setValue("/" + serial.data.title + "/seasons.json", forKey: "path")
                            return serialDict
                        }
                        resolve(serialsJSON)
                    } catch let error {
                        reject(error)
                    }
                }
            }.then { (serialsJSON: String) -> Promise<Files.FileMetadata> in
                return self.remoteDB.uploadFile(
                    "/serials.json",
                    body: serialsJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                )
            }.then { (_: Files.FileMetadata) -> [Serial] in
                return serialsWithSeasons
        }
    }
    
    func uploadSeasons(seasons: [Season], prefix: String) -> Promise<[Season]> {
        let seasonsWithChapters =
            seasons.filter { $0.chapters != nil }
        guard seasonsWithChapters.count != 0 else {
            return Promise(seasons)
        }
        return firstly { () -> Promise<[Files.FolderMetadata]> in
            // create folders first because I don't want to write JSON file
            // if an error happen
            let promises: [Promise<Files.FolderMetadata>] =
                seasonsWithChapters.map { (season: Season) -> Promise<Files.FolderMetadata> in
                    let folder = prefix + "/" + season.data.title
                    return self.remoteDB.createFolder(folder)
            }
            return join(promises)
            }.then { (_: [Files.FolderMetadata]) throws -> Promise<String> in
                return Promise { resolve, reject in
                    do {
                        let seasonsJSON = try SerialsService.toJSON(seasons) { season in
                            let seasonDict = NSMutableDictionary()
                            seasonDict.setValue(season.data.title, forKey: "title")
                            seasonDict.setValue(prefix + "/" + season.data.title + "/chapters.json", forKey:    "path")
                            return seasonDict
                        }
                        resolve(seasonsJSON)
                    } catch let error {
                        reject(error)
                    }
                }
            }.then { (seasonsJSON: String) -> Promise<Files.FileMetadata> in
                return self.remoteDB.uploadFile(
                    prefix + "/seasons.json",
                    body: seasonsJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                )
            }.then { _ in
                return seasonsWithChapters
        }
    }
    
    func uploadChapters(chapters: [Chapter], prefix: String) -> Promise<[Chapter]> {
        guard chapters.count != 0 else {
            return Promise(chapters)
        }
        return firstly { () -> Promise<[Files.FileMetadata]> in
            // uplaod files first because I don't want to write JSON file
            // if an error happen
            let promises =
                chapters.map { chapter in
                    return self.remoteDB.uploadFile(
                        prefix + "/" + chapter.data.title! + ".srt",
                        body: chapter.data.raw!.dataUsingEncoding(NSUTF8StringEncoding)!
                    )
            }
            return join(promises)
            }.then { (_: [Files.FileMetadata]) throws -> Promise<String> in
                return Promise { resolve, reject in
                    do {
                        let chaptersJSON = try SerialsService.toJSON(chapters) { chapter in
                            let chapterDict = NSMutableDictionary()
                            chapterDict.setValue(chapter.data.title, forKey: "title")
                            let chapterSrtPath = prefix + "/" + chapter.data.title! + ".srt"
                            chapterDict.setValue(chapterSrtPath, forKey: "path")
                            return chapterDict
                        }
                        resolve(chaptersJSON)
                    } catch let error {
                        reject(error)
                    }
                }
            }.then { (chaptersJSON: String) -> Promise<Files.FileMetadata> in
                return self.remoteDB.uploadFile(
                    prefix + "/chapters.json",
                    body: chaptersJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                )
            }.then { _ in
                return chapters
        }
    }
    
    static func toJSON<T>(items: [T], _ itemToDict: (T) -> NSMutableDictionary) throws -> String {
        let toDicts: [NSMutableDictionary] = items.map(itemToDict)
        let isValid = NSJSONSerialization.isValidJSONObject(toDicts)
        if !isValid {
            throw RemoteDBError.NotValid
        }
        var jsonString: String;
        do {
            let serialJSON = try NSJSONSerialization.dataWithJSONObject(toDicts, options: NSJSONWritingOptions())
            jsonString = NSString(data: serialJSON, encoding: NSUTF8StringEncoding) as! String
        } catch {
            throw RemoteDBError.Unknown
        }
        return jsonString;
    }
}