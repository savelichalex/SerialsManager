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
    
    lazy var serialsVC: SerialsViewController? = {
        guard let vc = NSApplication.sharedApplication().windows.first?.contentViewController?.childViewControllers[0] as? SerialsViewController else {
            return nil
        }
        return vc
    }()

    lazy var loadingSheet: LoadingSheetViewController = {
        return NSApplication.sharedApplication().windows.first!.contentViewController!.storyboard!.instantiateControllerWithIdentifier("LoadingSheet") as! LoadingSheetViewController
    }()
    
    let serialsService = SerialsService(db: DropboxDB())
    
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
        
        serialsService.getSerials().then { serials -> Void in
                self.serialsVC?.serials = serials
                self.serialsVC?.dismissViewController(self.loadingSheet)
            }.error { error in
                guard let err = error as? RemoteDBError else {
                    let err = error as NSError
                    self.loadingSheet.prepareForError(err.localizedDescription)
                    return
                }
                self.loadingSheet.prepareForError(err.description)
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
        serialsService.saveSerials(serials).then { _ -> Void in
                print("Success")
                self.serialsVC?.dismissViewController(self.loadingSheet)
            }.error { error in
                guard let err = error as? RemoteDBError else {
                    let err = error as NSError
                    self.loadingSheet.prepareForError(err.localizedDescription)
                    return
                }
                self.loadingSheet.prepareForError(err.description)
        }
    }

}
