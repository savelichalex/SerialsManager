//
//  ChapterDetailsViewController.swift
//  SerialsManager
//
//  Created by Admin on 03.08.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

class ChapterDetailsViewController: NSViewController {

    @IBOutlet var chapterRawTextView: NSTextView?
    
    @IBOutlet weak var chapterTitle: NSTextField?
    
    @IBOutlet weak var loadURL: NSTextField?
    
    var chapter: Chapter? {
        didSet {
            loadURL?.stringValue = ""
            chapterTitle?.stringValue = chapter?.data.title ?? ""
            chapterRawTextView?.textStorage?.mutableString.setString(chapter?.data.raw ?? "")
        }
    }
    
    func getCurrentData() -> (String?, String?) {
        return (
            chapterTitle?.stringValue,
            chapterRawTextView?.textStorage?.mutableString as String?
        )
    }
    
    @IBAction func loadContentFromURL(sender: NSButton) {
        if let urlString = loadURL?.stringValue {
            let url = NSURL(string: urlString)
            if url != nil {
                let request = NSURLRequest(URL: url!)
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
                    if error == nil {
                        if data != nil {
                            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                                self.chapterRawTextView?.textStorage?.mutableString.setString(String(data: data!, encoding: NSUTF8StringEncoding)!)
                                self.loadURL?.stringValue = ""
                            }
                        }
                    }
                }
                task.resume()
            }
        }
    }
}
