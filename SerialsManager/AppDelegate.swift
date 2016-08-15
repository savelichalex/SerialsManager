//
//  AppDelegate.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        if let path = NSBundle.mainBundle().pathForResource("AppConfig", ofType: "plist") {
            let appConfig = NSDictionary(contentsOfFile: path)
            print(appConfig)
            // use config somehow
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
            do {
                let serials = vc.getCurrentSerials()
                if serials != nil {
                    let serialsJSON = try toJSON(serials!) { serial in
                        let serialDict = NSMutableDictionary()
                        serialDict.setValue(serial.data.title, forKey: "title")
                        serialDict.setValue(serial.data.title + "/seasons.json", forKey: "seasons")
                        return serialDict
                    }
                    print(serialsJSON)
                    for serial in serials! {
                        // create folder for serial
                        if serial.seasons != nil {
                            let seasonsJSON = try toJSON(serial.seasons!) { season in
                                let seasonDict = NSMutableDictionary()
                                seasonDict.setValue(season.data.title, forKey: "title")
                                seasonDict.setValue(season.serial!.data.title + "/" + season.data.title + "/chapters.json", forKey: "chapters")
                                return seasonDict
                            }
                            print(seasonsJSON)
                            for season in serial.seasons! {
                                // create folder for season
                                if season.chapters != nil {
                                    let chaptersJSON = try toJSON(season.chapters!) { chapter in
                                        let chapterDict = NSMutableDictionary()
                                        chapterDict.setValue(chapter.data.title, forKey: "title")
                                        let chapterSrtPathFirstPart = chapter.season!.serial!.data.title + "/" + chapter.season!.data.title + "/"
                                        let chapterSrtPath = chapterSrtPathFirstPart + chapter.data.title! + ".srt"
                                        chapterDict.setValue(chapterSrtPath, forKey: "srt")
                                        return chapterDict
                                    }
                                    print(chaptersJSON)
                                    for chapter in season.chapters! {
                                        // save chapter raw
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
