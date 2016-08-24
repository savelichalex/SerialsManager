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

typealias EntityJSON = [String: AnyObject]

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        if let path = NSBundle.mainBundle().pathForResource("AppConfig", ofType: "plist") {
            let appConfig = NSDictionary(contentsOfFile: path)
            
            let dropboxAppKey = appConfig!["DropboxAppKey"] as! String
            let dropboxAccessToken = appConfig!["DropboxOAuthAccessToken"] as! String
            
            Dropbox.setupWithAppKey(dropboxAppKey)
            let client =
                DropboxClient(
                    accessToken: DropboxAccessToken(
                        accessToken: dropboxAccessToken,
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
            
            struct PromiseThroughState<T,V> {
                let state: T
                let lastResult: V
            }
            
            self.downloadJSON("/serials.json")
                .then { serials in
                    print(serials)
                }.error { error in
                    print(error)
            }
            
//            self.downloadJSON("/serials.json", json: serialsJSON)
//                .then { (serials: [EntityJSON]) ->
//                    Promise<PromiseThroughState<[EntityJSON],[[EntityJSON]]>> in
//                let promises =
//                    serials.map { self.downloadJSON("/" + $0.title + "/" + $0.path, json: seasonsJSON) }
//                
//                return join(promises)
//                    .then { result in
//                        return PromiseThroughState(
//                            state: serials,
//                            lastResult: result
//                        )
//                    }
//                }.then { state in
//                    
//                }.error { error in
//                let errorMirror = Mirror(reflecting: error)
//                print(errorMirror.subjectType)
//                print(error)
//            }
        }
        
    }
    
    func downloadJSON(path: String) -> Promise<[EntityJSON]> {
        return Promise { resolve, reject in
            guard let client = Dropbox.authorizedClient else {
                reject(SerialsError.Unauthorized)
                return
            }
            let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
                let fileManager = NSFileManager.defaultManager()
                let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                // generate a unique name for this file in case we've seen it before
                let UUID = NSUUID().UUIDString
                let pathComponent = "\(UUID)-\(response.suggestedFilename!)"
                return directoryURL.URLByAppendingPathComponent(pathComponent)
            }
            client.files.download(path: path, destination: destination)
                .response { response, error in
                    guard let (_, url) = response else {
                        reject(SerialsError.DownloadError(description: error!.description))
                        return
                    }
                    guard let data = NSData(contentsOfURL: url) else {
                        reject(SerialsError.DownloadError(description: "Empty file"))
                        return
                    }
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? [EntityJSON]
                        guard json != nil else {
                            reject(SerialsError.DownloadError(description: "Convert error"))
                            return
                        }
                        resolve(json!)
                    } catch {
                        reject(SerialsError.NotValid)
                    }
            }
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
        if let vc = NSApplication.sharedApplication().keyWindow?.contentViewController?.childViewControllers[0] as? SerialsViewController {
            let serials = vc.getCurrentSerials()
            guard (serials != nil) else {
                print("No one serial found")
                return
            }
            typealias Seasons = [Season];
            typealias Chapters = [Chapter];
            uploadSerials(serials!)
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
                }.then { _ in
                    print("Success")
                }.error { error in
                    let errorMirror = Mirror(reflecting: error)
                    print(errorMirror.subjectType)
                    print(error)
                }
        }
    }
    
    func uploadFile(path: String, body: NSData) -> Promise<Files.FileMetadata> {
        return Promise { resolve, reject in
            if let client = Dropbox.authorizedClient {
                client.files.upload(
                    path: path,
                    mode: .Overwrite,
                    body: body
                    ).response { response, error in
                        guard error == nil else {
                            reject(SerialsError.UploadError(description: error!.description))
                            return
                        }
                        resolve(response!)
                }
            } else {
                reject(SerialsError.Unauthorized)
            }
        }
    }
    
    func createFolder(path: String) -> Promise<Files.FolderMetadata> {
        return Promise { resolve, reject in
            if let client = Dropbox.authorizedClient {
                client.files.createFolder(
                    path: path
                    ).response { response, error in
                        guard error == nil else {
                            resolve(Files.FolderMetadata(name: path, pathLower: path))
                            return
                        }
                        resolve(response!)
                }
            } else {
                reject(SerialsError.Unauthorized)
            }
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
                    prefix + "/chapters.json",
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
