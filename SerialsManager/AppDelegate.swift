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
    
    enum SerialsSerializationError: ErrorType {
        case Empty
        case NotValid
        case Unknown
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    @IBAction func saveAll(sender: NSMenuItem) {
        if let vc = NSApplication.sharedApplication().keyWindow?.contentViewController?.childViewControllers[0] as? SerialsViewController {
            do {
                print(try serialsToJSON(vc.getCurrentSerials()))
            } catch SerialsSerializationError.Empty {
                print("Serials can't be empty")
            } catch SerialsSerializationError.NotValid {
                print("Serials JSON not valid")
            } catch SerialsSerializationError.Unknown {
                print("Unknown error while try serialize serials")
            } catch {
                print("Unknown error while try serialize serials")
            }
        }
    }
    
    func serialsToJSON(serials: [Serial]?) throws -> String {
        if serials == nil {
            throw SerialsSerializationError.Empty
        } else {
            let toDictsSerials: [NSMutableDictionary] = serials!.map { serial in
                let serialDict = NSMutableDictionary()
                serialDict.setValue(serial.data.title, forKey: "title")
                serialDict.setValue(serial.data.title, forKey: "path")
                return serialDict
            }
            let isValid = NSJSONSerialization.isValidJSONObject(toDictsSerials)
            if !isValid {
                throw SerialsSerializationError.NotValid
            }
            var jsonString: String;
            do {
                let serialJSON = try NSJSONSerialization.dataWithJSONObject(toDictsSerials, options: NSJSONWritingOptions())
                jsonString = NSString(data: serialJSON, encoding: NSUTF8StringEncoding) as! String
            } catch {
                throw SerialsSerializationError.Unknown
            }
            return jsonString;
        }
    }

}
