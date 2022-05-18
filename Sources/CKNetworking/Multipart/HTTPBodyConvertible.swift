//
//  HTTPBodyConvertible.swift
//
//
//  Created by Dmitriy Zharov on 18.08.2021.
//

import Foundation

public protocol HTTPBodyConvertible {
    func buildHTTPBodyPart(boundary: String) -> Data
}
