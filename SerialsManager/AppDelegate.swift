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

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

