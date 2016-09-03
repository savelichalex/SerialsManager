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

enum RemoteDBError: ErrorType, CustomStringConvertible {
    case DownloadError(description: String)
    case UploadError(description: String)
    case Unauthorized
    case NotValid
    case Unknown
    
    var description: String {
        switch self {
        case .DownloadError(let description): return description
        case .UploadError(let description): return description
        case .Unauthorized: return "Unauthorized"
        case .NotValid: return "JSON is not valid"
        case .Unknown: return "Unknow error"
        }
    }
}

protocol RemoteDB {
    static func downloadJSON(path: String) -> Promise<Entities>
    static func downloadData(path: String) -> Promise<NSData>
    static func createFolder(path: String) -> Promise<Files.FolderMetadata>
    static func uploadFile(path: String, body: NSData) -> Promise<Files.FileMetadata>
}