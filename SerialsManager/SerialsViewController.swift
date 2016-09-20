//
//  ViewController.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

class SerialsViewController: NSViewController {

    @IBOutlet weak var outlineView: NSOutlineView!


    var serials: [Serial]? {
        didSet {
            outlineView.reloadData()
        }
    }

    // MARK: - Actions

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
        switch outlineView.itemAtRow(selectedRow) {
        case let item as Season:
            let newChapter = addNewChapter(item)
            outlineView.reloadData()
            setChapterInChapterController(newChapter)
            let newRowIndex = selectedRow + (item.chapters?.count ?? 0)
            outlineView.expandItem(item)
            outlineView.selectRowIndexes(NSIndexSet(index: newRowIndex), byExtendingSelection: true)
            break
        case let item as Serial:
            addNewSeason(item)
            outlineView.reloadData()
            let newRowIndex = selectedRow + (item.seasons?.count ?? 0)
            outlineView.expandItem(item)
            outlineView.selectRowIndexes(NSIndexSet(index: newRowIndex), byExtendingSelection: true)
            break
        case is Chapter: break
        default:
            addNewSerial(&serials!)
            outlineView.reloadData()
        }
    }

    // MARK: - Some stuff

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

//MARK: - NSOutlineViewDataSource
extension SerialsViewController: NSOutlineViewDataSource {

    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        switch item {
            case let i as Serial:
                return i.seasons?.count ?? 0
            case let i as Season:
                return i.chapters?.count ?? 0
            case is Chapter:
                return 0
            default:
                return serials?.count ?? 0
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
            case let i as Serial:
                return i.seasons?.count > 0
            case let i as Season:
                return i.chapters?.count > 0
            case is Chapter:
                return false
            default:
                return false
        }
    }

}

// MARK: - NSOutlineViewDelegate
extension SerialsViewController: NSOutlineViewDelegate {

    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        switch item {
        case let i as Serial:
            let view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Serial: " + i.data.title
                textField.sizeToFit()
            }
            return view
        case let i as Season:
            let view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Season: " + i.data.title
                textField.sizeToFit()
            }
            return view
        case let i as Chapter:
            let view = outlineView.makeViewWithIdentifier("SerialItemCell", owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = "Chapter " + (i.data.title ?? "unknown")
                textField.sizeToFit()
            }
            return view
        default:
            return nil
        }
    }

}
