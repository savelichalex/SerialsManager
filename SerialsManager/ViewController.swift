//
//  ViewController.swift
//  SerialsManager
//
//  Created by Admin on 04.07.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    let dbPath = NSURL.fileURLWithPath("/Users/admin/friends-db")
    
    var serials: [Serial]?

    override func viewDidLoad() {
        super.viewDidLoad()

        serials = getSerials(dbPath)
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already l oaded.
        }
    }

}

extension ViewController: NSOutlineViewDataSource {
    
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
        } else if let i = item as? Chapter {
            return 0
        }
        
        return serials!.count
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let i = item as? Serial {
            return i.seasons?[index]
        } else if let i = item as? Season {
            return i.chapters?[index]
        }
        
        return serials?[index]
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        if let i = item as? Serial {
            return i.seasons != nil
        } else if let i = item as? Season {
            i.chapters != nil
        } else if let i = item as? Chapter {
            return false
        }
        
        return false
    }
    
}