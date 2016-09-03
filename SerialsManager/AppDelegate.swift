//
//  AppDelegate.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa
import SwiftyDropbox
import PromiseKit

typealias JSON = [String: AnyObject]

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    lazy var serialsVC: SerialsViewController? = {
        guard let vc = NSApplication.sharedApplication().windows.first?.contentViewController?.childViewControllers[0] as? SerialsViewController else {
            return nil
        }
        return vc
    }()

    lazy var loadingSheet: LoadingSheetViewController = {
        return NSApplication.sharedApplication().windows.first!.contentViewController!.storyboard!.instantiateControllerWithIdentifier("LoadingSheet") as! LoadingSheetViewController
    }()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        guard let appKey = SecretConfig.DropboxAppKey,
            let accessToken = SecretConfig.DropboxOAuthAccessToken else {
                return
        }
        if let sVC = serialsVC {
            sVC.presentViewControllerAsSheet(loadingSheet)
            loadingSheet.prepareForDownload(sVC)
        }
        
        Dropbox.setupWithAppKey(appKey)
        let client =
            DropboxClient(
                accessToken: DropboxAccessToken(
                    accessToken: accessToken,
                    uid: "")
        )
        Dropbox.authorizedClient = client
        DropboxClient.sharedClient = client
        client.users.getCurrentAccount().response { response, error in
            if let account = response {
                print("Hello \(account.name.givenName)")
            } else {
                let errorMirror = Mirror(reflecting: error)
                print(errorMirror.subjectType)
                print(error)
            }
        }
        
        self.downloadJSON("/serials.json")
            .then { serials in
                let promises =
                    serials.map {
                        self.downloadJSON($0.path)
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
                            self.downloadJSON($0.path)
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
                            self.downloadData($0.path)
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
                return self.getSerials(serials, seasons, chapters)
            }.then { serials -> Void in
                self.serialsVC?.serials = serials
                self.serialsVC?.dismissViewController(self.loadingSheet)
            }.error { error in
                guard let err = error as? SerialsError else {
                    let err = error as NSError
                    self.loadingSheet.prepareForError(err.localizedDescription)
                    return
                }
                self.loadingSheet.prepareForError(err.description)
        }
    }
    
    enum SerialsError: ErrorType, CustomStringConvertible {
        case DownloadError(description: String)
        case UploadError(description: String)
        case Unauthorized
        case NotValid
        case Unknown
        
        var description: String {
            switch self {
                case .DownloadError(let description): return description
                case .UploadError(let description): return description
                case .Unauthorized: return "Unauthorized"
                case .NotValid: return "JSON is not valid"
                case .Unknown: return "Unknow error"
            }
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func saveAll(sender: NSMenuItem) {
        guard let serials = serialsVC?.getCurrentSerials() else {
            print("No one serial found")
            return
        }
        if let sVC = serialsVC {
            sVC.presentViewControllerAsSheet(loadingSheet)
            loadingSheet.prepareForDownload(sVC)
        }
        typealias Seasons = [Season];
        typealias Chapters = [Chapter];
        uploadSerials(serials)
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
                print("Success")
                self.serialsVC?.dismissViewController(self.loadingSheet)
            }.error { error in
                guard let err = error as? SerialsError else {
                    let err = error as NSError
                    self.loadingSheet.prepareForError(err.localizedDescription)
                    return
                }
                self.loadingSheet.prepareForError(err.description)
        }
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
                        return self.createFolder("/" + serial.data.title)
                }
                return join(promises)
            }.then { (_: [Files.FolderMetadata]) throws -> Promise<String> in
                return Promise { resolve, reject in
                    do {
                        let serialsJSON = try self.toJSON(serials) { serial in
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
                return self.uploadFile(
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
                        return self.createFolder(folder)
                }
                return join(promises)
            }.then { (_: [Files.FolderMetadata]) throws -> Promise<String> in
                return Promise { resolve, reject in
                    do {
                        let seasonsJSON = try self.toJSON(seasons) { season in
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
                return self.uploadFile(
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
                        return self.uploadFile(
                            prefix + "/" + chapter.data.title! + ".srt",
                            body: chapter.data.raw!.dataUsingEncoding(NSUTF8StringEncoding)!
                    )
                }
                return join(promises)
            }.then { (_: [Files.FileMetadata]) throws -> Promise<String> in
                return Promise { resolve, reject in
                    do {
                        let chaptersJSON = try self.toJSON(chapters) { chapter in
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
                return self.uploadFile(
                    prefix + "/chapters.json",
                    body: chaptersJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                )
            }.then { _ in
                return chapters
        }
    }
    
    func toJSON<T>(items: [T], _ itemToDict: (T) -> NSMutableDictionary) throws -> String {
        let toDicts: [NSMutableDictionary] = items.map(itemToDict)
        let isValid = NSJSONSerialization.isValidJSONObject(toDicts)
        if !isValid {
            throw SerialsError.NotValid
        }
        var jsonString: String;
        do {
            let serialJSON = try NSJSONSerialization.dataWithJSONObject(toDicts, options: NSJSONWritingOptions())
            jsonString = NSString(data: serialJSON, encoding: NSUTF8StringEncoding) as! String
        } catch {
            throw SerialsError.Unknown
        }
        return jsonString;
    }

}
