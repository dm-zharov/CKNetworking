//
//  MultipartData+HTTPBodyConvertible.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation

extension MultipartData: HTTPBodyConvertible {
    public func buildHTTPBodyPart(boundary: String) -> Data {
        let httpBody = NSMutableData()
        httpBody.appendString("--\(boundary)\r\n")
        httpBody.appendString("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(fileName)\"\r\n")
        httpBody.appendString("Content-Type: \(mimeType)\r\n\r\n")
        httpBody.append(fileData)
        httpBody.appendString("\r\n")
        
        return httpBody as Data
    }
}

internal extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}
