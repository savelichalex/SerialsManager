//
//  RemoteDB.swift
//  SerialsManager
//
//  Created by Admin on 03.09.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation
import SwiftyDropbox
import PromiseKit

struct EntityJSON {
    let title: String
    let path: String
}

typealias Entities = [EntityJSON]

protocol RemoteDB {
    static func downloadJSON(path: String) -> Promise<Entities>
    static func downloadData(path: String) -> Promise<NSData>
    static func createFolder(path: String) -> Promise<Files.FolderMetadata>
    static func uploadFile(body: NSData) -> Promise<Files.FileMetadata>
}