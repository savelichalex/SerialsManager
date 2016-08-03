//
//  ViewController.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

class SerialsViewController: NSViewController {
    
    let dbPath = NSURL.fileURLWithPath("/Users/admin/friends-db")
    
    var serials: [Serial]?
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serials = getSerials(dbPath)
        // Do any additional setup after loading the view.
    }
    
    @IBAction func clickOnCell(sender: NSOutlineView) {
        let item = sender.itemAtRow(sender.clickedRow)
        if let i = item as? Serial {
            print(i.data.title)
        } else if let i = item as? Season {
            print(i.data.title)
        } else if let i = item as? Chapter {
            if let chapterController = self.parentViewController?.childViewControllers[1] as? ChapterDetailsViewController {
                chapterController.chapter = i
            }
        }
    }
}

extension SerialsViewController: NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let i = item as? Serial {
            if i.seasons != nil {
                return i.seasons!.count
            } else {
                return 0
            }
        } else if let i = item as? Season {
            if i.chapters != nil {
                return i.chapters!.count
            } else {
                return 0
            }
        } else if ((item as? Chapter) != nil) {
            return 0
        }
        
        return serials!.count
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let i = item as? Serial {
            return (i.seasons?[index])!
        } else if let i = item as? Season {
            return (i.chapters?[index])!
        }
        
        return (serials?[index])!
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let i = item as? Serial {
            return i.seasons != nil
        } else if let i = item as? Season {
            return i.chapters != nil
        } else if ((item as? Chapter) != nil) {
            return false
        }
        
        return false
    }
    
}

extension SerialsViewController: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        var view: NSTableCellView?
        
        if let i = item as? Serial {
            view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Serial: " + i.data.title
                textField.sizeToFit()
            }
        } else if let i = item as? Season {
            view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Season: " + i.data.title
                textField.sizeToFit()
            }
        } else if let i = item as? Chapter {
            view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Chapter: " + i.data.title
                textField.sizeToFit()
            }
        }
        
        return view
    }
}