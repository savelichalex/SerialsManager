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
        if let chapterController = self.parentViewController?.childViewControllers[1] as? ChapterDetailsViewController {
            if let currentChapter = chapterController.chapter {
                let text = chapterController.getCurrentData()
                updateChapterData(currentChapter, text: text)
                outlineView.reloadData()
                outlineView.selectRowIndexes(NSIndexSet(index: sender.clickedRow), byExtendingSelection: true)
            }
        }
        if let i = item as? Chapter {
            setChapterInChapterController(i)
        }
    }
    
    @IBAction func addNewEntity(sender: NSButton) {
        let selectedRow = outlineView.selectedRow
        if selectedRow == -1 {
            return
        }
        if let item = outlineView.itemAtRow(selectedRow) as? Season {
            let newChapter = addNewChapter(item)
            outlineView.reloadData()
            setChapterInChapterController(newChapter)
            let newRowIndex = selectedRow + item.chapters!.count
            outlineView.expandItem(item)
            outlineView.selectRowIndexes(NSIndexSet(index: newRowIndex), byExtendingSelection: true)
        }
    }
    
    func setChapterInChapterController(chapter: Chapter) -> Bool {
        if let chapterController = self.parentViewController?.childViewControllers[1] as? ChapterDetailsViewController {
            chapterController.chapter = chapter
            return true
        } else {
            return false
        }
    }
    
    func getCurrentSerials() -> [Serial]? {
        return serials
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
                textField.stringValue = "Chapter " + (i.data.title ?? "unknown")
                textField.sizeToFit()
            }
        }
        
        return view
    }
}