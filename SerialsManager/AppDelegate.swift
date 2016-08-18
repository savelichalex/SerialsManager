//
//  AppDelegate.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa
import SwiftyDropbox

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
    
    enum SerializationError: ErrorType {
        case NotValid
        case Unknown
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func saveAll(sender: NSMenuItem) {
        if let vc = NSApplication.sharedApplication().keyWindow?.contentViewController?.childViewControllers[0] as? SerialsViewController {
            let serials = vc.getCurrentSerials()
            if serials != nil {
                uploadSerials(serials!)
            }
        }
    }
    
    func uploadSerials(serials: [Serial]) {
        do {
            if let client = Dropbox.authorizedClient {
                let serialsJSON = try toJSON(serials) { serial in
                    let serialDict = NSMutableDictionary()
                    serialDict.setValue(serial.data.title, forKey: "title")
                    serialDict.setValue("/" + serial.data.title + "/seasons.json", forKey: "seasons")
                    return serialDict
                }
                print("Upload to /serials.json")
                client.files.upload(
                    path: "/serials.json",
                    body: serialsJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                    ).response { response, error in
                        if response != nil {
                            for serial in serials {
                                if serial.seasons != nil {
                                    print("Create folder \(serial.data.title)")
                                    client.files.createFolder(
                                        path: serial.data.title
                                        ).response { response, error in
                                            if response != nil {
                                                self.uploadSeasons(
                                                    serial.seasons!,
                                                    prefix: "/" + serial.data.title
                                                )
                                            } else {
                                                print(error!)
                                            }
                                    }
                                }
                            }
                        } else {
                            print(error!)
                        }
                }
            }
        } catch SerializationError.NotValid {
            print("JSON not valid")
        } catch SerializationError.Unknown {
            print("Unknown error while try serialize")
        } catch {
            print("Unknown error while try serialize")
        }
    }
    
    func uploadSeasons(seasons: [Season], prefix: String) {
        do {
            if let client = Dropbox.authorizedClient {
                let seasonsJSON = try self.toJSON(seasons) { season in
                    let seasonDict = NSMutableDictionary()
                    seasonDict.setValue(season.data.title, forKey: "title")
                    seasonDict.setValue(prefix + "/" + season.data.title + "/chapters.json", forKey: "chapters")
                    return seasonDict
                }
                print("Upload to \(prefix + "/chapters.json")")
                client.files.upload(
                    path: prefix + "/chapters.json",
                    body: seasonsJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                    ).response {
                        response, error in
                        if response != nil {
                            for season in seasons {
                                if season.chapters != nil {
                                    // create folder for season
                                    print("Create folder \(prefix + "/" + season.data.title)")
                                    client.files.createFolder(
                                        path: prefix + "/" + season.data.title
                                        ).response { response, error in
                                            if response != nil {
                                                self.uploadChapters(
                                                    season.chapters!,
                                                    prefix: prefix + "/" + season.data.title
                                                )
                                            } else {
                                                print(error!)
                                            }
                                    }
                                }
                            }
                        } else {
                            print(error!)
                        }
                }
            }
        } catch SerializationError.NotValid {
            print("JSON not valid")
        } catch SerializationError.Unknown {
            print("Unknown error while try serialize")
        } catch {
            print("Unknown error while try serialize")
        }
    }
    
    func uploadChapters(chapters: [Chapter], prefix: String) {
        do {
            if let client = Dropbox.authorizedClient {
                let chaptersJSON = try self.toJSON(chapters) { chapter in
                    let chapterDict = NSMutableDictionary()
                    chapterDict.setValue(chapter.data.title, forKey: "title")
                    let chapterSrtPathFirstPart = chapter.season!.serial!.data.title + "/" + chapter.season!.data.title + "/"
                    let chapterSrtPath = chapterSrtPathFirstPart + chapter.data.title! + ".srt"
                    chapterDict.setValue(chapterSrtPath, forKey: "srt")
                    return chapterDict
                }
                client.files.upload(
                    path: prefix + "/chapters.json",
                    body: chaptersJSON.dataUsingEncoding(NSUTF8StringEncoding)!
                ).response { response, error in
                    if response != nil {
                        for chapter in chapters {
                            // save chapter raw
                            client.files.upload(
                                path: prefix + "/" + chapter.data.title! + ".srt",
                                body: chapter.data.raw!.dataUsingEncoding(NSUTF8StringEncoding)!
                            ).response { response, error in
                                if response == nil {
                                    print(error!)
                                }
                            }
                        }
                    }
                }
            }
        } catch SerializationError.NotValid {
            print("JSON not valid")
        } catch SerializationError.Unknown {
            print("Unknown error while try serialize")
        } catch {
            print("Unknown error while try serialize")
        }
    }
    
    func toJSON<T>(items: [T], _ itemToDict: (T) -> NSMutableDictionary) throws -> String {
        let toDicts: [NSMutableDictionary] = items.map(itemToDict)
        let isValid = NSJSONSerialization.isValidJSONObject(toDicts)
        if !isValid {
            throw SerializationError.NotValid
        }
        var jsonString: String;
        do {
            let serialJSON = try NSJSONSerialization.dataWithJSONObject(toDicts, options: NSJSONWritingOptions())
            jsonString = NSString(data: serialJSON, encoding: NSUTF8StringEncoding) as! String
        } catch {
            throw SerializationError.Unknown
        }
        return jsonString;
    }

}
