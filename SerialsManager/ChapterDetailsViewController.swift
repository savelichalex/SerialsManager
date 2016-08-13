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
    var chapter: Chapter? {
        didSet {
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
}
