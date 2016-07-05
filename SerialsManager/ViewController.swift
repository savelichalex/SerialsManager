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

    override func viewDidLoad() {
        super.viewDidLoad()

        getSeasons()
        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already l oaded.
        }
    }
    
    func getSeasons() {
        let serials = getSerials(dbPath)
        if serials != nil {
            print(serials!.first!.seasons!.first!.chapters!.first!.title)
        }
    }

}

