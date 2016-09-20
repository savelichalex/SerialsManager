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

    func getCurrentData() -> String? {
        return chapterRawTextView?.textStorage?.mutableString as String?
    }

    @IBAction func loadContentFromURL(sender: NSButton) {
        guard let urlString = loadURL?.stringValue, url = NSURL(string: urlString) else {
            return
        }

        let request = NSURLRequest(URL: url)
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { (data, response, error) in
            guard let data = data,
                      strData = String(data: data, encoding: NSUTF8StringEncoding)
                where error == nil
            else {
                return
            }

            dispatch_async(dispatch_get_main_queue()) { [unowned self] in
                self.chapterRawTextView?.textStorage?.mutableString.setString(strData)
                self.loadURL?.stringValue = ""
            }
        }
        task.resume()
    }
}
