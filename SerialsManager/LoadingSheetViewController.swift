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
    
    let downloadText = "Loading serials data"
    let uploadText = "Save serials data"
    let errorText = "Oops, something happens"
    
    func prepareForDownload() -> LoadingSheetViewController {
        sheetTitle?.stringValue = downloadText
        return self
    }
    
    func preparedForUpload() -> LoadingSheetViewController {
        sheetTitle?.stringValue = uploadText
        return self
    }
    
    func prepareForError() -> LoadingSheetViewController {
        sheetTitle?.stringValue = errorText
        return self
    }
}

