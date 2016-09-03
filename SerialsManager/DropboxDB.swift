//
//  DropboxDB.swift
//  SerialsManager
//
//  Created by Admin on 03.09.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import Foundation
import PromiseKit
import SwiftyDropbox

class DropboxDB : RemoteDB {
    static func downloadJSON(path: String) -> Promise<Entities> {
        return Promise { resolve, reject in
            guard let client = Dropbox.authorizedClient else {
                reject(RemoteDBError.Unauthorized)
                return
            }
            let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
                let fileManager = NSFileManager.defaultManager()
                let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                // generate a unique name for this file in case we've seen it before
                let UUID = NSUUID().UUIDString
                let pathComponent = "\(UUID)-\(response.suggestedFilename!)"
                return directoryURL.URLByAppendingPathComponent(pathComponent)
            }
            client.files.download(path: path, destination: destination)
                .response { response, error in
                    guard let (_, url) = response else {
                        reject(RemoteDBError.DownloadError(description: error!.description))
                        return
                    }
                    guard let data = NSData(contentsOfURL: url) else {
                        reject(RemoteDBError.DownloadError(description: "Empty file"))
                        return
                    }
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) as? [JSON]
                        guard json != nil else {
                            reject(RemoteDBError.DownloadError(description: "Convert error"))
                            return
                        }
                        resolve(json!.map {
                            let title = $0["title"] as! String
                            let path = $0["path"] as! String
                            return EntityJSON(title: title, path: path)
                            })
                    } catch {
                        reject(RemoteDBError.NotValid)
                    }
            }
        }
    }
    
    static func downloadData(path: String) -> Promise<NSData> {
        return Promise { resolve, reject in
            guard let client = Dropbox.authorizedClient else {
                reject(RemoteDBError.Unauthorized)
                return
            }
            let destination : (NSURL, NSHTTPURLResponse) -> NSURL = { temporaryURL, response in
                let fileManager = NSFileManager.defaultManager()
                let directoryURL = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
                // generate a unique name for this file in case we've seen it before
                let UUID = NSUUID().UUIDString
                let pathComponent = "\(UUID)-\(response.suggestedFilename!)"
                return directoryURL.URLByAppendingPathComponent(pathComponent)
            }
            client.files.download(path: path, destination: destination)
                .response { response, error in
                    guard let (_, url) = response else {
                        reject(RemoteDBError.DownloadError(description: error!.description))
                        return
                    }
                    guard let data = NSData(contentsOfURL: url) else {
                        reject(RemoteDBError.DownloadError(description: "Empty file"))
                        return
                    }
                    resolve(data)
            }
        }
    }
    
    static func createFolder(path: String) -> Promise<Files.FolderMetadata> {
        return Promise { resolve, reject in
            guard let client = Dropbox.authorizedClient else {
                reject(RemoteDBError.Unauthorized)
                return
            }
            client.files.createFolder(
                path: path
                ).response { response, error in
                    guard error == nil else {
                        resolve(Files.FolderMetadata(name: path, pathLower: path))
                        return
                    }
                    resolve(response!)
            }
        }
    }
    
    static func uploadFile(path: String, body: NSData) -> Promise<Files.FileMetadata> {
        return Promise { resolve, reject in
            guard let client = Dropbox.authorizedClient else {
                reject(RemoteDBError.Unauthorized)
                return
            }
            client.files.upload(
                path: path,
                mode: .Overwrite,
                body: body
                ).response { response, error in
                    guard error == nil else {
                        reject(RemoteDBError.UploadError(description: error!.description))
                        return
                    }
                    resolve(response!)
            }
        }
    }
}