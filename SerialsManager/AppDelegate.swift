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
                    print(error)
                }
            }
        }
        
    }
    
    enum SerialsError: ErrorType, CustomStringConvertible {
        case UploadError(description: String)
        case NotValid
        case Unknown
        
        var description: String {
            switch self {
                case .UploadError(let description): return description
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
            uploadSerials(serials!)
                .then { (serials: [Serial]) -> Promise<[Seasons]> in
//                    let seasons: [Seasons] =
//                        serials.map { $0.seasons! }
                    let promises: [Promise<Seasons>] =
                        serials.map { serial in
                            return self.uploadSeasons(
                                serial.seasons!,
                                prefix: "/" + serial.data.title
                            )
                        }
                    
                    let afterAll: Promise<[Seasons]> = join(promises)
                    
                    return afterAll
                }
                .then { (seasons: [Seasons]) -> Seasons in
                    return seasons.reduce([], combine: +)
                }.then { _ in
                    print("Success")
                }.error { error in
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
                reject("Unauthorized" as! ErrorType)
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
                reject("Unauthorized" as! ErrorType)
            }
        }
    }
    
    func uploadSerials(serials: [Serial]) -> Promise<[Serial]> {
        return Promise { resolve, reject in
            do {
                let serialsJSON = try self.toJSON(serials) { serial in
                    let serialDict = NSMutableDictionary()
                    serialDict.setValue(serial.data.title, forKey: "title")
                    serialDict.setValue("/" + serial.data.title + "/seasons.json", forKey: "seasons")
                    return serialDict
                }
                resolve(serialsJSON)
            } catch let error {
                reject(error)
            }
        }.then { (serialsJSON: String) -> Promise<Files.FileMetadata> in
            return self.uploadFile(
                "/serials.json",
                body: serialsJSON.dataUsingEncoding(NSUTF8StringEncoding)!
            )
        }.then { _ in
            let serialsWithSeasons =
                serials.filter {
                    $0.seasons != nil
                }
            let promises =
                serialsWithSeasons.map { (serial: Serial) -> Promise<Files.FolderMetadata> in
                    return self.createFolder("/" + serial.data.title)
                }
            return join(promises)
                .then { _ in
                    return serialsWithSeasons
            }
        }
    }
    
    func uploadSeasons(seasons: [Season], prefix: String) -> Promise<[Season]> {
        return Promise { resolve, reject in
            do {
                let seasonsJSON = try self.toJSON(seasons) { season in
                    let seasonDict = NSMutableDictionary()
                    seasonDict.setValue(season.data.title, forKey: "title")
                    seasonDict.setValue(prefix + "/" + season.data.title + "/chapters.json", forKey:    "chapters")
                    return seasonDict
                }
                resolve(seasonsJSON)
            } catch let error {
                reject(error)
            }
        }.then { (seasonsJSON: String) -> Promise<Files.FileMetadata> in
            return self.uploadFile(
                prefix + "/chapters.json",
                body: seasonsJSON.dataUsingEncoding(NSUTF8StringEncoding)!
            )
        }.then { _ in
            let seasonsWithChapters =
                seasons.filter { $0.chapters != nil }
            let promises =
                seasonsWithChapters.map { (season: Season) -> Promise<Files.FolderMetadata> in
                    let folder = prefix + "/" + season.data.title
                    return self.createFolder(folder)
            }
            return join(promises)
                .then { _ in
                    return seasonsWithChapters
            }
        }
    }
//
//    func uploadChapters(chapters: [Chapter], prefix: String) -> (_: Files.FolderMetadata) -> Promise<Void> {
//        return Promise { resolve, reject in
//            do {
//                let chaptersJSON = try self.toJSON(chapters) { chapter in
//                    let chapterDict = NSMutableDictionary()
//                    chapterDict.setValue(chapter.data.title, forKey: "title")
//                    let chapterSrtPath = prefix + "/" + chapter.data.title! + ".srt"
//                    chapterDict.setValue(chapterSrtPath, forKey: "srt")
//                    return chapterDict
//                }
//                resolve(chaptersJSON)
//            } catch let error {
//                reject(error)
//            }
//        }.then { (chaptersJSON: String) -> Promise<Files.FileMetadata> in
//            return self.uploadFile(
//                prefix + "/chapters.json",
//                body: chaptersJSON.dataUsingEncoding(NSUTF8StringEncoding)!
//            )
//        }.then { _ in
//            let promises =
//                chapters.map { chapter in
//                    return self.uploadFile(
//                        prefix + "/" + chapter.data.title! + ".srt",
//                        body: chapter.data.raw!.dataUsingEncoding(NSUTF8StringEncoding)!
//                    )
//            }
//            return when(promises).then { _ in
//                print("Uploaded")
//            }
//        }
//    }
    
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
