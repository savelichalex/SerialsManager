//
//  BabelRPCClient+Promise.swift
//  SerialsManager
//
//  Created by Admin on 19.08.16.
//  Copyright © 2016 savelichalex. All rights reserved.
//

import SwiftyDropbox
import Alamofire

extension BabelUploadRequest {
    func responsePromise() -> Promise<RType.ValueType> {
        return promise { resolve, reject in
            self.response { response, error in
                if error != nil {
                    reject(error as! ErrorType)
                } else {
                    resolve(response!)
                }
            }
        }
    }
}

extension BabelRpcRequest {
    func responsePromise() -> Promise<RType.ValueType> {
        return promise { resolve, reject in
            self.response { response, error in
                if error != nil {
                    reject(error as! ErrorType)
                } else {
                    resolve(response!)
                }
            }
        }
    }
}