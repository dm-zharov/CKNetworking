//
//  Params+HTTPBodyConvertible.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation

extension Params: HTTPBodyConvertible {
    public func buildHTTPBodyPart(boundary: String) -> Data {
        let httpBody = NSMutableData()
        forEach { name, value in
            httpBody.appendString("--\(boundary)\r\n")
            httpBody.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            httpBody.appendString((value as AnyObject).description)
            httpBody.appendString("\r\n")
        }
        
        return httpBody as Data
    }
}
