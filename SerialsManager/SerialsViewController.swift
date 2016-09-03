//
//  ViewController.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

class SerialsViewController: NSViewController {
    
    var serials: [Serial]? {
        didSet{
            outlineView.reloadData()
        }
    }
    
    @IBOutlet weak var outlineView: NSOutlineView!
    
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
        switch item {
            case let i as Serial: return i.seasons != nil ? i.seasons!.count : 0
            case let i as Season: return i.chapters != nil ? i.chapters!.count : 0
            case is Chapter: return 0
            default: return serials != nil ? serials!.count : 0
        }
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        switch item {
            case let i as Serial: return (i.seasons?[index])!
            case let i as Season: return (i.chapters?[index])!
            default: return (serials?[index])!
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        switch item {
            case let i as Serial: return i.seasons != nil ? i.seasons!.count > 0 : false
            case let i as Season: return i.chapters != nil ? i.chapters!.count > 0 : false
            case is Chapter: return false
            default: return false
        }
    }
    
}

extension SerialsViewController: NSOutlineViewDelegate {
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        var view: NSTableCellView?
        
        switch item {
        case let i as Serial:
            view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Serial: " + i.data.title
                textField.sizeToFit()
            }
            break
        case let i as Season:
            view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Season: " + i.data.title
                textField.sizeToFit()
            }
            break
        case let i as Chapter:
            view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Chapter " + (i.data.title ?? "unknown")
                textField.sizeToFit()
            }
        default: ()
        }
        
        return view
    }
}