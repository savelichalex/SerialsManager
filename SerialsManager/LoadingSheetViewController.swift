//
//  LoadingSheetViewController.swift
//  SerialsManager
//
//  Created by Admin on 28.08.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

class LoadingSheetViewController: NSViewController {
    
    @IBOutlet weak var sheetTitle: NSTextField?
    
    @IBOutlet weak var closeSheet: NSButton?
    
    @IBOutlet weak var sheetDescription: NSTextField?
    @IBOutlet weak var progressbar: NSProgressIndicator?
    
    weak var outterVC: NSViewController? = nil
    
    let downloadText = "Loading serials data"
    let uploadText = "Save serials data"
    let errorText = "Oops, something happens"
    
    @IBAction func closeSheetAction(sender: NSButton) {
        outterVC?.dismissViewController(self)
        outterVC = nil
    }
    
    func prepareForDownload(vc: NSViewController) -> LoadingSheetViewController {
        outterVC = vc
        sheetTitle?.stringValue = downloadText
        sheetDescription?.hidden = true
        progressbar?.hidden = false
        closeSheet?.hidden = true
        return self
    }
    
    func preparedForUpload(vc: NSViewController) -> LoadingSheetViewController {
        outterVC = vc
        sheetTitle?.stringValue = uploadText
        sheetDescription?.hidden = true
        progressbar?.hidden = false
        closeSheet?.hidden = true
        return self
    }
    
    func prepareForForkedBuildWarning(vc: NSViewController) -> LoadingSheetViewController {
        return prepareForError(vc, description: "Hey, looks like you want to" +
            " manually build SerialsManager." +
            " Please contact with me (email: savelichalex93@gmail.com)" +
            " to get detailed description how do this.")
    }
    
    func prepareForError(description: String) -> LoadingSheetViewController {
        sheetTitle?.stringValue = errorText
        sheetDescription?.stringValue = description
        sheetDescription?.hidden = false
        progressbar?.hidden = true
        closeSheet?.hidden = false
        return self
    }
    
    func prepareForError(vc: NSViewController, description: String) -> LoadingSheetViewController {
        outterVC = vc
        return prepareForError(description)
    }
}

